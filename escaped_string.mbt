///|
fn Machine::escaped_string(self : Machine) -> Array[Byte] raise ForthError {
  let frame = self.source_frame()
  let result = []
  while frame.cursor < frame.data.length() {
    let byte = frame.data[frame.cursor]
    frame.cursor += 1
    if byte == b'"' {
      return result
    }
    if byte != b'\\' {
      result.push(byte)
      continue
    }
    if frame.cursor >= frame.data.length() {
      raise Invalid("unterminated escape")
    }
    let escape = frame.data[frame.cursor]
    frame.cursor += 1
    if escape == b'x' {
      if frame.cursor + 2 > frame.data.length() {
        raise Invalid("short hexadecimal escape")
      }
      let a = digit_value(frame.data[frame.cursor].to_int().to_uint16())
      let b = digit_value(frame.data[frame.cursor + 1].to_int().to_uint16())
      if a < 0 || a > 15 || b < 0 || b > 15 {
        raise Invalid("invalid hexadecimal escape")
      }
      frame.cursor += 2
      result.push((a * 16 + b).to_byte())
    } else if escape == b'm' {
      result.push(13)
      result.push(10)
    } else {
      result.push(
        match escape {
          b'a' => 7
          b'b' => 8
          b'e' => 27
          b'f' => 12
          b'l' | b'n' => 10
          b'q' | b'"' => 34
          b'r' => 13
          b't' => 9
          b'v' => 11
          b'z' => 0
          b'\\' => 92
          _ => raise Invalid("unknown string escape")
        },
      )
    }
  }
  raise Invalid("unterminated escaped string")
}
