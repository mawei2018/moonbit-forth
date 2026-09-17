///|
pub suberror ForthError {
  Invalid(String)
  Thrown(Int)
} derive(Debug)

///|
pub struct Machine {
  priv stack : Array[Int]
  priv words : Map[String, Array[String]]
  priv immediate_words : Map[String, Bool]
  priv mut latest_name : String?
  priv mut compile_output : Array[String]?
  priv mut compilation_state : Bool
  priv mut compile_eval : Bool
  priv data_addresses : Map[String, Int]
  priv mut latest_created : Array[String]?
  priv sources : Array[SourceFrame]
  priv strings : Array[Byte]
  priv string_cache : Map[String, (Int, Int)]
  priv scratch : Array[Byte]
  priv terminal : Array[Byte]
  priv mut base : Int
  priv mut catch_depth : Int
  priv mut active_compiler : Compiler?
  priv execution_tokens : Array[Array[String]]
  priv mut binding_id : Int
  priv output : Array[String]
  priv memory : Array[Byte]
  priv returns : Array[Int]
  priv mut return_base : Int
  priv loop_indices : Array[Int]
  priv mut exiting : Bool
  priv mut loop_base : Int
  priv mut in_word : Bool
  priv mut leaving : Bool
  priv mut fuel : Int
} derive(Debug)

///|
pub fn Machine::new() -> Machine {
  {
    stack: [],
    words: {},
    binding_id: 0,
    execution_tokens: [],
    immediate_words: {},
    latest_name: None,
    compile_output: None,
    compilation_state: false,
    compile_eval: false,
    data_addresses: {},
    latest_created: None,
    sources: [],
    strings: [],
    string_cache: {},
    scratch: Array::make(1024, b'\x00'),
    terminal: [],
    base: 10,
    catch_depth: 0,
    active_compiler: None,
    output: [],
    memory: [],
    returns: [],
    return_base: 0,
    loop_indices: [],
    exiting: false,
    loop_base: 0,
    in_word: false,
    leaving: false,
    fuel: 0,
  }
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
    let raw = code[pc]
    let builtin = raw.has_prefix("\u0001")
    let word = if builtin { raw[1:].to_owned() } else { raw }
    pc += 1
    if raw.has_prefix("\u0002") {
      self.emit_postponed(raw[1:].to_owned())
    } else if word == "'" {
      let (name, next) = self.runtime_name(code, pc, depth)
      pc = next
      self.stack.push(self.capture_xt(name))
    } else if word == "variable" || word == "constant" || word == "create" {
      if self.compile_eval {
        raise Invalid("defining words during compilation are unsupported")
      }
      let (name, next) = self.runtime_name(code, pc, depth)
      pc = next
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
      let data_body = [value.to_string()]
      if word == "create" {
        let identity = self.binding_key()
        self.words[identity] = []
        self.data_addresses[identity] = value
        data_body.push(identity)
        self.latest_created = Some(data_body)
      } else {
        self.latest_created = None
      }
      self.words[name] = data_body
      self.latest_name = Some(name)
      self.immediate_words[name] = false
    } else if word == "does>" {
      self.attach_does(code[pc:].to_owned())
      return
    } else if word == ":" || word == ":noname" {
      if self.compile_eval {
        raise Invalid("nested compilation")
      }
      let anonymous = word == ":noname"
      let name = if anonymous {
        self.binding_key()
      } else {
        self.source_name().to_lower()
      }
      if self.read_number(name) is Some(_) ||
        [";", ":", ":noname"].contains(name) {
        raise Invalid("invalid definition name")
      }
      self.compile_word(name, depth)
    } else if word == "do" || word == "?do" {
      let (body, plus, next) = counted_body(code, pc)
      pc = next
      let start = self.pop()
      let limit = self.pop()
      if word == "do" || start != limit {
        self.counted_loop(body, start, limit, plus, depth + 1)
      }
    } else if word == "begin" {
      let (body, tail, ending, next) = begin_body(code, pc)
      pc = next
      while true {
        self.fuel -= 1
        if self.fuel < 0 {
          raise Invalid("execution budget exhausted")
        }
        self.execute(body, depth + 1)
        if self.leaving || self.exiting {
          return
        }
        if ending == "until" {
          if self.pop() != 0 {
            break
          }
        } else if ending == "repeat" {
          if self.pop() == 0 {
            break
          }
          self.execute(tail, depth + 1)
          if self.leaving || self.exiting {
            return
          }
        }
      }
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
    } else if [
        ";", "else", "then", "while", "repeat", "until", "again", "loop", "+loop",
      ].contains(word) {
      raise Invalid("unexpected control word: " + word)
    } else if !builtin && self.words.get(word) is Some(body) {
      self.execute_frame(body, depth + 1, true)
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
            self.save(address + i, value.to_int(), false)
          }
        }
        "move" => {
          let count = self.pop()
          let dest = self.pop()
          let source = self.pop()
          self.memory_range(source, count)
          self.memory_range(dest, count)
          let copy = self.read_bytes(source, count)
          for i in 0..<count {
            self.save(dest + i, copy[i].to_int(), false)
          }
        }
        "0=" | "0<" | "0>" | "1+" | "1-" => {
          let value = self.pop()
          self.stack.push(
            match word {
              "0=" => if value == 0 { -1 } else { 0 }
              "0<" => if value < 0 { -1 } else { 0 }
              "0>" => if value > 0 { -1 } else { 0 }
              "1+" => value + 1
              _ => value - 1
            },
          )
        }
        "i" | "j" => {
          let back = if word == "i" { 1 } else { 2 }
          if self.loop_indices.length() < back {
            raise Invalid("loop index unavailable")
          }
          self.stack.push(self.loop_indices[self.loop_indices.length() - back])
        }
        "exit" => {
          if !self.in_word {
            raise Invalid("EXIT outside definition")
          }
          if self.loop_indices.length() != self.loop_base {
            raise Invalid("EXIT requires UNLOOP for active loops")
          }
          if self.returns.length() != self.return_base {
            raise Invalid("EXIT requires balanced return stack")
          }
          self.exiting = true
          return
        }
        "unloop" => {
          if !self.in_word || self.loop_indices.length() <= self.loop_base {
            raise Invalid("UNLOOP outside current word loop")
          }
          ignore(self.loop_indices.pop())
        }
        "leave" => {
          if self.loop_indices.is_empty() {
            raise Invalid("LEAVE outside counted loop")
          }
          self.leaving = true
          return
        }
        ">r" | "r>" | "r@" | "2>r" | "2r>" | "2r@" => self.return_word(word)
        "state" => self.stack.push(-4)
        "immediate" => {
          if self.compile_eval {
            raise Invalid("IMMEDIATE during active compilation is unsupported")
          }
          match self.latest_name {
            Some(name) => self.immediate_words[name] = true
            None => raise Invalid("IMMEDIATE requires a named definition")
          }
        }
        "compile," => {
          let output = match self.compile_output {
            Some(output) => output
            None => raise Invalid("COMPILE, outside compilation")
          }
          let xt = self.pop()
          if xt < 1 || xt > self.execution_tokens.length() {
            raise Invalid("invalid execution token")
          }
          if output.length() >= 65534 {
            raise Invalid("compiled definition limit")
          }
          output.push(xt.to_string())
          output.push("\u0001execute")
        }
        ">body" => {
          let xt = self.pop()
          self.stack.push(self.body_address(xt))
        }
        "execute" => {
          let xt = self.pop()
          if xt < 1 || xt > self.execution_tokens.length() {
            raise Invalid("invalid execution token")
          }
          self.execute_frame(self.execution_tokens[xt - 1], depth + 1, true)
        }
        "depth" => self.stack.push(self.stack.length())
        "." => {
          let text = self.format_integer(self.pop(), false)
          self.output.push(text)
          self.write_text(text + " ")
        }
        "abs"
        | "min"
        | "max"
        | "/mod"
        | "*/"
        | "*/mod"
        | "2*"
        | "2/"
        | "invert"
        | "xor"
        | "lshift"
        | "rshift"
        | "u<"
        | "u>"
        | "within"
        | "<>"
        | "0<>" => self.integer_word(word)
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
        _ => self.text_word(word, depth)
      }
    }
    if self.leaving || self.exiting {
      return
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
  ignore(self.eval_chunk(source, budget, false))
}

///|
/// Feed a complete input buffer, keeping an unfinished definition for the next call.
pub fn Machine::feed(
  self : Machine,
  source : String,
  budget? : Int = 10000,
) -> Bool raise ForthError {
  self.eval_chunk(source, budget, true)
}

///|
pub fn Machine::is_compiling(self : Machine) -> Bool {
  self.active_compiler is Some(_)
}

///|
fn Machine::eval_chunk(
  self : Machine,
  source : String,
  budget : Int,
  allow_pending : Bool,
) -> Bool raise ForthError {
  if budget < 1 || source.length() > 1000000 {
    raise Invalid("invalid input limit")
  }
  self.fuel = budget
  let return_base = self.returns.length()
  defer (while self.returns.length() > return_base {
    ignore(self.returns.pop())
  })
  errdefer {
    self.abort_compilation()
    self.exiting = false
    self.leaving = false
  }
  self.interpret_source(source, 1)
  if self.returns.length() != return_base {
    raise Invalid("unbalanced return stack at eval boundary")
  }
  if !allow_pending && self.active_compiler is Some(_) {
    raise Invalid("unterminated definition")
  }
  self.is_compiling()
}
