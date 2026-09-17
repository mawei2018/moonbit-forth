///|
fn text_primitive(word : String) -> Bool {
  ["save-input", "restore-input", "refill"].contains(word) ||
  string_word(word) ||
  [
    "char", "char+", "chars", "bl", "count", "type", "emit", "cr", "space", "spaces",
    "base", "hex", "decimal", "u.", ".r", "u.r", "source", "source-id", ">in", "parse",
    "parse-name", "word", "pad", "evaluate", "catch", "throw", "abort", "abort-message",
    "-trailing", "/string", "compare", "search", "blank", "?dup", "2over", "pick",
    "roll", "true", "false", "2@", "2!", "unused",
  ].contains(word)
}

///|
fn Machine::text_word(
  self : Machine,
  word : String,
  depth : Int,
) -> Unit raise ForthError {
  match word {
    "char" => self.stack.push(@utf8.encode(self.source_name())[0].to_int())
    "chars" => {
      let n = self.pop()
      self.stack.push(n)
    }
    "char+" => {
      let n = self.pop()
      self.stack.push(n + 1)
    }
    "bl" => self.stack.push(32)
    "count" => {
      let address = self.pop()
      let n = self.load(address, false)
      self.stack.push(address + 1)
      self.stack.push(n)
    }
    "type" => {
      let count = self.pop()
      let address = self.pop()
      let data = self.read_bytes(address, count)
      self.write_bytes(data)
    }
    "emit" => self.write_bytes([self.pop().to_byte()])
    "cr" => self.write_text("\n")
    "space" => self.write_text(" ")
    "spaces" => {
      let count = self.pop()
      if count > 2000000 {
        raise Invalid("output byte limit")
      }
      if count > 0 {
        self.write_bytes(Array::make(count, b' '))
      }
    }
    "base" => self.stack.push(-8)
    "hex" => self.base = 16
    "decimal" => self.base = 10
    "u." | ".r" | "u.r" => {
      let width = if word == "u." { 0 } else { self.pop() }
      let text = self.format_integer(self.pop(), word != ".r")
      if width > 2000000 {
        raise Invalid("output byte limit")
      }
      if width > text.length() {
        self.write_bytes(Array::make(width - text.length(), b' '))
      }
      self.write_text(text + (if word == "u." { " " } else { "" }))
    }
    "source" => {
      let frame = self.source_frame()
      self.stack.push(frame.address)
      self.stack.push(frame.data.length())
    }
    "source-id" => self.stack.push(-1)
    ">in" => self.stack.push(-12)
    "parse" => {
      let delimiter = self.pop()
      let (address, count) = self.parse_source(delimiter, false)
      self.stack.push(address)
      self.stack.push(count)
    }
    "parse-name" => {
      let frame = self.source_frame()
      while frame.cursor < frame.data.length() &&
            frame.data[frame.cursor].to_int() <= 32 {
        frame.cursor += 1
      }
      let start = frame.cursor
      ignore(frame.name())
      let mut end = frame.cursor
      if end > start && frame.data[end - 1].to_int() <= 32 {
        end -= 1
      }
      self.stack.push(frame.address + start)
      self.stack.push(end - start)
    }
    "word" => {
      let delimiter = self.pop()
      let (address, count) = self.parse_source(delimiter, true)
      if count > 255 {
        raise Invalid("WORD exceeds 255 bytes")
      }
      let data = self.read_bytes(address, count)
      self.scratch[0] = count.to_byte()
      for i, byte in data {
        self.scratch[i + 1] = byte
      }
      self.stack.push(65536)
    }
    "pad" => self.stack.push(65792)
    "evaluate" => {
      let count = self.pop()
      let address = self.pop()
      let text = @utf8.decode(
        Bytes::from_array(self.read_bytes(address, count)[:])[:],
      ) catch {
        _ => raise Invalid("EVALUATE requires UTF-8")
      }
      self.interpret_source(text, depth + 1)
    }
    "catch" => self.catch_word(depth)
    "throw" => {
      let code = self.pop()
      if code != 0 {
        raise Thrown(code)
      }
    }
    "abort" => raise Thrown(-1)
    "abort-message" => {
      let count = self.pop()
      let address = self.pop()
      let flag = self.pop()
      if flag != 0 {
        if self.catch_depth == 0 {
          self.write_bytes(self.read_bytes(address, count))
        }
        raise Thrown(-2)
      }
    }
    "save-input" => {
      let frame = self.source_frame()
      self.stack.push(frame.cursor)
      self.stack.push(frame.address)
      self.stack.push(2)
    }
    "restore-input" => {
      let n = self.pop()
      if n < 0 || n > self.stack.length() {
        raise Invalid("invalid saved input dimensions")
      }
      if n != 2 {
        for _ in 0..<n {
          ignore(self.pop())
        }
        self.stack.push(-1)
      } else {
        let address = self.pop()
        let cursor = self.pop()
        let frame = self.source_frame()
        if address != frame.address ||
          cursor < 0 ||
          cursor > frame.data.length() {
          self.stack.push(-1)
        } else {
          frame.cursor = cursor
          self.stack.push(0)
        }
      }
    }
    "refill" => self.stack.push(0)
    "-trailing" => {
      let count = self.pop()
      let address = self.pop()
      let data = self.read_bytes(address, count)
      let mut end = count
      while end > 0 && data[end - 1] == b' ' {
        end -= 1
      }
      self.stack.push(address)
      self.stack.push(end)
    }
    "/string" => {
      let n = self.pop()
      let count = self.pop()
      let address = self.pop()
      if n < 0 || n > count {
        raise Invalid("invalid /STRING range")
      }
      self.stack.push(address + n)
      self.stack.push(count - n)
    }
    "compare" | "search" => self.compare_string(word)
    "blank" => {
      let count = self.pop()
      let address = self.pop()
      self.memory_range(address, count)
      for i in 0..<count {
        self.save(address + i, 32, false)
      }
    }
    "?dup" => {
      let value = self.pop()
      self.stack.push(value)
      if value != 0 {
        self.stack.push(value)
      }
    }
    "2over" => {
      let n = self.stack.length()
      if n < 4 {
        raise Invalid("stack underflow")
      }
      let a = self.stack[n - 4]
      let b = self.stack[n - 3]
      self.stack.push(a)
      self.stack.push(b)
    }
    "pick" | "roll" => {
      let offset = self.pop()
      if offset < 0 || offset >= self.stack.length() {
        raise Invalid("invalid stack index")
      }
      let i = self.stack.length() - 1 - offset
      let value = self.stack[i]
      if word == "roll" {
        for j in i..<(self.stack.length() - 1) {
          self.stack[j] = self.stack[j + 1]
        }
        ignore(self.stack.pop())
      }
      self.stack.push(value)
    }
    "true" => self.stack.push(-1)
    "false" => self.stack.push(0)
    "unused" => self.stack.push(65536 - self.memory.length())
    "2@" => {
      let address = self.pop()
      let low = self.load(address + 4, true)
      let high = self.load(address, true)
      self.stack.push(low)
      self.stack.push(high)
    }
    "2!" => {
      let address = self.pop()
      let high = self.pop()
      let low = self.pop()
      self.memory_range(address, 8)
      self.save(address, high, true)
      self.save(address + 4, low, true)
    }
    _ =>
      if string_word(word) {
        self.execute(self.string_code(word), depth)
      } else {
        raise Invalid("unknown word: " + word)
      }
  }
}

///|
fn Machine::compare_string(
  self : Machine,
  word : String,
) -> Unit raise ForthError {
  let length2 = self.pop()
  let address2 = self.pop()
  let length1 = self.pop()
  let address1 = self.pop()
  let a = self.read_bytes(address1, length1)
  let b = self.read_bytes(address2, length2)
  if word == "compare" {
    for i in 0..<length1.min(length2) {
      if a[i] != b[i] {
        self.stack.push(if a[i] < b[i] { -1 } else { 1 })
        return
      }
    }
    self.stack.push(
      if length1 < length2 {
        -1
      } else if length1 > length2 {
        1
      } else {
        0
      },
    )
  } else {
    if length2 == 0 {
      self.stack.push(address1)
      self.stack.push(length1)
      self.stack.push(-1)
      return
    }
    let prefix = Array::make(length2, 0)
    let mut matched = 0
    for i in 1..<length2 {
      while matched > 0 && b[i] != b[matched] {
        matched = prefix[matched - 1]
      }
      if b[i] == b[matched] {
        matched += 1
      }
      prefix[i] = matched
      self.fuel -= 1
      if self.fuel < 0 {
        raise Invalid("execution budget exhausted")
      }
    }
    matched = 0
    for i in 0..<length1 {
      while matched > 0 && a[i] != b[matched] {
        matched = prefix[matched - 1]
      }
      if a[i] == b[matched] {
        matched += 1
      }
      self.fuel -= 1
      if self.fuel < 0 {
        raise Invalid("execution budget exhausted")
      }
      if matched == length2 {
        let offset = i + 1 - length2
        self.stack.push(address1 + offset)
        self.stack.push(length1 - offset)
        self.stack.push(-1)
        return
      }
    }
    self.stack.push(address1)
    self.stack.push(length1)
    self.stack.push(0)
  }
}
