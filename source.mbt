///|
priv struct SourceFrame {
  data : Bytes
  address : Int
  mut cursor : Int
} derive(Debug)

///|
fn Machine::source_frame(self : Machine) -> SourceFrame raise ForthError {
  match self.sources.last() {
    Some(frame) => frame
    None => raise Invalid("no active input source")
  }
}

///|
fn SourceFrame::name(self : SourceFrame) -> String {
  while self.cursor < self.data.length() &&
        self.data[self.cursor].to_int() <= 32 {
    self.cursor += 1
  }
  let start = self.cursor
  while self.cursor < self.data.length() && self.data[self.cursor].to_int() > 32 {
    self.cursor += 1
  }
  let end = self.cursor
  if self.cursor < self.data.length() {
    self.cursor += 1
  }
  @utf8.decode_lossy(self.data[start:end])
}

///|
fn Machine::source_name(self : Machine) -> String raise ForthError {
  let name = self.source_frame().name()
  if name.is_empty() {
    raise Invalid("missing input name")
  }
  name
}

///|
fn Machine::parse_source(
  self : Machine,
  delimiter : Int,
  skip : Bool,
) -> (Int, Int) raise ForthError {
  if delimiter < 0 || delimiter > 255 {
    raise Invalid("delimiter must be a byte")
  }
  let frame = self.source_frame()
  if skip {
    while frame.cursor < frame.data.length() &&
          frame.data[frame.cursor].to_int() == delimiter {
      frame.cursor += 1
    }
  }
  let start = frame.cursor
  while frame.cursor < frame.data.length() &&
        frame.data[frame.cursor].to_int() != delimiter {
    frame.cursor += 1
  }
  let length = frame.cursor - start
  if frame.cursor < frame.data.length() {
    frame.cursor += 1
  }
  (frame.address + start, length)
}

///|
fn Machine::delimited(
  self : Machine,
  delimiter : Int,
) -> String raise ForthError {
  let frame = self.source_frame()
  let start = frame.cursor
  let (_, length) = self.parse_source(delimiter, false)
  if start + length == frame.data.length() {
    raise Invalid("unterminated string or comment")
  }
  @utf8.decode_lossy(frame.data[start:start + length])
}

///|
fn Machine::next_source_word(self : Machine) -> String raise ForthError {
  while true {
    let original = self.source_frame().name()
    let word = if original.length() == 3 &&
      original[0] == '\'' &&
      original[2] == '\'' {
      original
    } else {
      original.to_lower()
    }
    if word == "(" {
      ignore(self.delimited(41))
      continue
    }
    if word == "\\" {
      ignore(self.parse_source(10, false))
      continue
    }
    return word
  } nobreak {
    ""
  }
}

///|
fn Machine::intern_string(
  self : Machine,
  text : String,
  counted : Bool,
) -> (Int, Int) raise ForthError {
  self.intern_bytes(@utf8.encode(text).to_array(), counted)
}

///|
fn Machine::intern_bytes(
  self : Machine,
  bytes : Array[Byte],
  counted : Bool,
) -> (Int, Int) raise ForthError {
  let builder = StringBuilder()
  builder.write_string(if counted { "c" } else { "s" })
  for byte in bytes {
    builder.write_char(byte.to_char())
  }
  let key = builder.to_string()
  if self.string_cache.get(key) is Some(pair) {
    return pair
  }
  if counted && bytes.length() > 255 {
    raise Invalid("counted string exceeds 255 bytes")
  }
  if self.strings.length() + bytes.length() + (if counted { 2 } else { 1 }) >
    16000000 {
    raise Invalid("string storage limit")
  }
  let address = 1048576 + self.strings.length()
  if counted {
    self.strings.push(bytes.length().to_byte())
  }
  for byte in bytes {
    self.strings.push(byte)
  }
  self.strings.push(0)
  let pair = (address, bytes.length())
  self.string_cache[key] = pair
  pair
}

///|
fn Machine::string_code(
  self : Machine,
  word : String,
) -> Array[String] raise ForthError {
  if word == "s\\\"" {
    let (address, length) = self.intern_bytes(self.escaped_string(), false)
    return [address.to_string(), length.to_string()]
  }
  let text = self.delimited(if word == ".(" { 41 } else { 34 })
  if word == ".(" {
    self.write_text(text)
    return []
  }
  let (address, length) = self.intern_string(text, word == "c\"")
  if word == "c\"" {
    return [address.to_string()]
  }
  let code = [address.to_string(), length.to_string()]
  if word == ".\"" {
    code.push("\u0001type")
  }
  if word == "abort\"" {
    code.push("\u0001abort-message")
  }
  code
}

///|
fn string_word(word : String) -> Bool {
  ["s\"", ".\"", "c\"", ".(", "s\\\"", "abort\""].contains(word)
}

///|
fn Machine::source_control(
  self : Machine,
  first : String,
) -> Array[String] raise ForthError {
  let code = [first]
  let mut nesting = 1
  while nesting > 0 {
    self.fuel -= 1
    if self.fuel < 0 {
      raise Invalid("execution budget exhausted")
    }
    let word = self.next_source_word()
    if word.is_empty() {
      raise Invalid("unclosed source control structure")
    }
    if string_word(word) {
      for token in self.string_code(word) {
        code.push(token)
      }
      continue
    }
    if ["if", "begin", "do", "?do"].contains(word) {
      nesting += 1
    }
    if ["then", "until", "again", "repeat", "loop", "+loop"].contains(word) {
      nesting -= 1
    }
    code.push(
      if self.read_number(word) is Some(n) {
        n.to_string()
      } else {
        word
      },
    )
  }
  validate_structure(code)
  code
}

///|
fn Machine::interpret_token(
  self : Machine,
  word : String,
  depth : Int,
) -> Unit raise ForthError {
  if string_word(word) {
    self.execute(self.string_code(word), depth)
  } else if ["if", "begin", "do", "?do"].contains(word) {
    self.execute(self.source_control(word), depth)
  } else if !self.words.contains(word) &&
    !primitive_word(word) &&
    self.read_number(word) is Some(n) {
    self.execute([n.to_string()], depth)
  } else {
    self.execute([word], depth)
  }
}

///|
fn Machine::consume_source(
  self : Machine,
  word : String,
  depth : Int,
) -> Unit raise ForthError {
  if self.active_compiler is Some(compiler) {
    self.fuel -= 1
    if self.fuel < 0 {
      raise Invalid("execution budget exhausted")
    }
    if word == ";" {
      if !self.compilation_state {
        raise Invalid("missing closing bracket")
      }
      self.finish_compilation(compiler)
    } else if !self.compilation_state {
      if word == "]" {
        compiler.bracket_stack = None
        self.compilation_state = true
      } else if word == "[" {
        raise Invalid("nested interpretation bracket")
      } else {
        self.interpret_token(word, depth)
      }
    } else {
      self.compile_token(compiler, word, depth)
    }
  } else {
    self.interpret_token(word, depth)
  }
}

///|
fn Machine::interpret_source(
  self : Machine,
  source : String,
  depth : Int,
) -> Unit raise ForthError {
  if self.sources.length() >= 64 || depth > 64 || source.length() > 1000000 {
    raise Invalid("input source limit")
  }
  let data = @utf8.encode(source)
  for byte in data {
    if byte.to_int() < 3 {
      raise Invalid("reserved source character")
    }
  }
  let frame = SourceFrame::{
    data,
    address: 1000000000 + self.sources.length() * 4000000,
    cursor: 0,
  }
  self.sources.push(frame)
  defer ignore(self.sources.pop())
  while true {
    let word = self.next_source_word()
    if word.is_empty() {
      break
    }
    self.consume_source(word, depth)
  }
}
