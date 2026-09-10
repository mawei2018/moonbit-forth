///|
pub suberror ForthError {
  Invalid(String)
} derive(Debug)

///|
pub struct Machine {
  priv stack : Array[Int]
  priv words : Map[String, Array[String]]
  priv output : Array[String]
  priv memory : Array[Byte]
  priv mut fuel : Int
} derive(Debug)

///|
pub fn Machine::new() -> Machine {
  { stack: [], words: {}, output: [], memory: [], fuel: 0, }
}

///|
pub fn Machine::values(self : Machine) -> Array[Int] {
  self.stack.copy()
}

///|
pub fn Machine::printed(self : Machine) -> String {
  self.output.join(" ")
}

///|
fn Machine::pop(self : Machine) -> Int raise ForthError {
  match self.stack.pop() {
    Some(v) => v
    None => raise Invalid("stack underflow")
  }
}

///|
fn tokens(source : String) -> Array[String] raise ForthError {
  let out = []
  let mut word = ""
  let mut comment = false
  let mut line_comment = false
  for c in source.iter() {
    if line_comment {
      if c == '\n' {
        line_comment = false
      }
      continue
    }
    if comment {
      if c == ')' {
        comment = false
      }
      continue
    }
    if c == '(' || c == '\\' || c == ' ' || c == '\n' || c == '\r' || c == '\t' {
      if word != "" {
        out.push(word.to_lower())
        word = ""
      }
      if c == '(' {
        comment = true
      }
      if c == '\\' {
        line_comment = true
      }
    } else {
      word += c.to_string()
    }
  }
  if comment {
    raise Invalid("unterminated comment")
  }
  if word != "" {
    out.push(word.to_lower())
  }
  out
}

///|
fn number(s : String) -> Int? {
  if s == "" || s == "-" {
    return None
  }
  let neg = s.has_prefix("-")
  let mut n : Int64 = 0L
  for i in (if neg { 1 } else { 0 })..<s.length() {
    let d = s[i].to_int() - 48
    if d < 0 || d > 9 {
      return None
    }
    n = n * 10L + d.to_int64()
    if n > (if neg { 2147483648L } else { 2147483647L }) {
      return None
    }
  }
  (if neg { -n } else { n }).to_int() |> Some
}

///|
fn Machine::execute(
  self : Machine,
  code : Array[String],
  depth : Int,
) -> Unit raise ForthError {
  if depth > 64 {
    raise Invalid("call depth exceeded")
  }
  let mut pc = 0
  while pc < code.length() {
    self.fuel -= 1
    if self.fuel < 0 {
      raise Invalid("execution budget exhausted")
    }
    let word = code[pc]
    pc += 1
    if word == "variable" || word == "constant" || word == "create" {
      if pc >= code.length() {
        raise Invalid("missing data word name")
      }
      let name = code[pc]
      pc += 1
      if number(name) is Some(_) ||
        [":", ";", "if", "else", "then"].contains(name) {
        raise Invalid("invalid data word name")
      }
      let value = if word == "constant" {
        self.pop()
      } else {
        self.allocate((4 - self.memory.length() % 4) % 4)
        let address = self.memory.length()
        if word == "variable" {
          self.allocate(4)
        }
        address
      }
      self.words[name] = [value.to_string()]
    } else if word == ":" {
      if pc >= code.length() {
        raise Invalid("missing definition name")
      }
      let name = code[pc]
      pc += 1
      if number(name) is Some(_) || name == ";" || name == ":" {
        raise Invalid("invalid definition name")
      }
      let body = []
      while pc < code.length() && code[pc] != ";" {
        if code[pc] == ":" {
          raise Invalid("nested definition")
        }
        body.push(code[pc])
        pc += 1
      }
      if pc == code.length() {
        raise Invalid("unterminated definition")
      }
      pc += 1
      self.words[name] = body
    } else if word == "if" {
      let condition = self.pop()
      let yes = []
      let no = []
      let mut nesting = 1
      let mut alternative = false
      while pc < code.length() {
        let t = code[pc]
        pc += 1
        if t == "if" {
          nesting += 1
        }
        if t == "then" {
          nesting -= 1
        }
        if nesting == 0 {
          break
        }
        if t == "else" && nesting == 1 {
          if alternative {
            raise Invalid("duplicate else")
          }
          alternative = true
        } else if alternative {
          no.push(t)
        } else {
          yes.push(t)
        }
      }
      if nesting != 0 {
        raise Invalid("missing then")
      }
      self.execute(if condition != 0 { yes } else { no }, depth + 1)
    } else if word == ";" || word == "else" || word == "then" {
      raise Invalid("unexpected control word: " + word)
    } else if self.words.get(word) is Some(body) {
      self.execute(body, depth + 1)
    } else if number(word) is Some(n) {
      self.stack.push(n)
    } else {
      match word {
        "dup" => {
          let a = self.pop()
          self.stack.push(a)
          self.stack.push(a)
        }
        "drop" => ignore(self.pop())
        "swap" => {
          let b = self.pop()
          let a = self.pop()
          self.stack.push(b)
          self.stack.push(a)
        }
        "over" => {
          let b = self.pop()
          let a = self.pop()
          self.stack.push(a)
          self.stack.push(b)
          self.stack.push(a)
        }
        "rot" => {
          let c = self.pop()
          let b = self.pop()
          let a = self.pop()
          self.stack.push(b)
          self.stack.push(c)
          self.stack.push(a)
        }
        "nip" => {
          let b = self.pop()
          ignore(self.pop())
          self.stack.push(b)
        }
        "tuck" => {
          let b = self.pop()
          let a = self.pop()
          self.stack.push(b)
          self.stack.push(a)
          self.stack.push(b)
        }
        "2dup" => {
          let b = self.pop()
          let a = self.pop()
          self.stack.push(a)
          self.stack.push(b)
          self.stack.push(a)
          self.stack.push(b)
        }
        "2drop" => {
          ignore(self.pop())
          ignore(self.pop())
        }
        "2swap" => {
          let d = self.pop()
          let c = self.pop()
          let b = self.pop()
          let a = self.pop()
          self.stack.push(c)
          self.stack.push(d)
          self.stack.push(a)
          self.stack.push(b)
        }
        "here" => self.stack.push(self.memory.length())
        "allot" => {
          let count = self.pop()
          self.allocate(count)
        }
        "align" => self.allocate((4 - self.memory.length() % 4) % 4)
        "aligned" => {
          let n = self.pop()
          self.stack.push((n + 3) & -4)
        }
        "cells" => {
          let n = self.pop()
          self.stack.push(n * 4)
        }
        "cell+" => {
          let n = self.pop()
          self.stack.push(n + 4)
        }
        "@" | "c@" => {
          let address = self.pop()
          self.stack.push(self.load(address, word == "@"))
        }
        "!" | "c!" | "+!" => {
          let address = self.pop()
          let value = self.pop()
          let next = if word == "+!" {
            self.load(address, true) + value
          } else {
            value
          }
          self.save(address, next, word != "c!")
        }
        "," | "c," => {
          let value = self.pop()
          let address = self.memory.length()
          if word == "," && address % 4 != 0 {
            raise Invalid("unaligned comma")
          }
          self.allocate(if word == "," { 4 } else { 1 })
          self.save(address, value, word == ",")
        }
        "fill" | "erase" => {
          let value = if word == "fill" {
            self.pop().to_byte()
          } else {
            b'\x00'
          }
          let count = self.pop()
          let address = self.pop()
          self.memory_range(address, count)
          for i in 0..<count {
            self.memory[address + i] = value
          }
        }
        "move" => {
          let count = self.pop()
          let dest = self.pop()
          let source = self.pop()
          self.memory_range(source, count)
          self.memory_range(dest, count)
          let copy = self.memory[source:source + count].to_owned()
          for i in 0..<count {
            self.memory[dest + i] = copy[i]
          }
        }
        "depth" => self.stack.push(self.stack.length())
        "." => self.output.push(self.pop().to_string())
        "negate" => {
          let a = self.pop()
          self.stack.push(-a)
        }
        "+" | "-" | "*" | "/" | "mod" | "=" | "<" | ">" | "and" | "or" => {
          let b = self.pop()
          let a = self.pop()
          if (word == "/" || word == "mod") &&
            (b == 0 || (a == -2147483648 && b == -1)) {
            raise Invalid("invalid division")
          }
          self.stack.push(
            match word {
              "+" => a + b
              "-" => a - b
              "*" => a * b
              "/" => a / b
              "mod" => a % b
              "=" => if a == b { -1 } else { 0 }
              "<" => if a < b { -1 } else { 0 }
              ">" => if a > b { -1 } else { 0 }
              "and" => a & b
              _ => a | b
            },
          )
        }
        _ => raise Invalid("unknown word: " + word)
      }
    }
    if self.stack.length() > 4096 {
      raise Invalid("stack limit exceeded")
    }
  }
}

///|
/// State changes before an error are retained. Integer arithmetic uses 32-bit cells.
pub fn Machine::eval(
  self : Machine,
  source : String,
  budget? : Int = 10000,
) -> Unit raise ForthError {
  if budget < 1 || source.length() > 1000000 {
    raise Invalid("invalid input limit")
  }
  self.fuel = budget
  self.execute(tokens(source), 0)
}
