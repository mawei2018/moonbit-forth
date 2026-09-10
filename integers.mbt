///|
fn Machine::integer_word(
  self : Machine,
  word : String,
) -> Unit raise ForthError {
  let count = match word {
    "within" | "*/" | "*/mod" => 3
    "abs" | "2*" | "2/" | "invert" | "0<>" => 1
    _ => 2
  }
  if self.stack.length() < count {
    raise Invalid("stack underflow")
  }
  let c = self.pop()
  if count == 1 {
    self.stack.push(
      match word {
        "abs" => if c < 0 { -c } else { c }
        "2*" => c << 1
        "2/" => c >> 1
        "invert" => c.lnot()
        _ => if c != 0 { -1 } else { 0 }
      },
    )
    return
  }
  let b = self.pop()
  if word == "*/" || word == "*/mod" || word == "/mod" {
    let numerator = if word == "/mod" {
      b.to_int64()
    } else {
      self.pop().to_int64() * b.to_int64()
    }
    if c == 0 {
      raise Invalid("division by zero")
    }
    let quotient = numerator / c.to_int64()
    if quotient < -2147483648L || quotient > 2147483647L {
      raise Invalid("quotient outside cell range")
    }
    if word != "*/" {
      self.stack.push((numerator % c.to_int64()).to_int())
    }
    self.stack.push(quotient.to_int())
    return
  }
  if word == "within" {
    let a = self.pop()
    self.stack.push(
      if (a - b).reinterpret_as_uint() < (c - b).reinterpret_as_uint() {
        -1
      } else {
        0
      },
    )
    return
  }
  if (word == "lshift" || word == "rshift") && (c < 0 || c >= 32) {
    raise Invalid("shift outside cell width")
  }
  self.stack.push(
    match word {
      "min" => if b < c { b } else { c }
      "max" => if b > c { b } else { c }
      "xor" => b ^ c
      "lshift" => b << c
      "rshift" => (b.reinterpret_as_uint() >> c).reinterpret_as_int()
      "u<" =>
        if b.reinterpret_as_uint() < c.reinterpret_as_uint() {
          -1
        } else {
          0
        }
      "u>" =>
        if b.reinterpret_as_uint() > c.reinterpret_as_uint() {
          -1
        } else {
          0
        }
      _ => if b != c { -1 } else { 0 }
    },
  )
}
