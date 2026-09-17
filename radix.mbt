///|
fn digit_value(c : UInt16) -> Int {
  if c >= '0' && c <= '9' {
    c.to_int() - 48
  } else if c >= 'a' && c <= 'z' {
    c.to_int() - 97 + 10
  } else if c >= 'A' && c <= 'Z' {
    c.to_int() - 65 + 10
  } else {
    -1
  }
}

///|
fn Machine::read_number(self : Machine, source : String) -> Int? {
  if source.is_empty() {
    return None
  }
  if source.length() == 3 && source[0] == '\'' && source[2] == '\'' {
    return Some(source[1].to_int())
  }
  let mut radix = self.base
  let mut start = 0
  if source[0] == '$' {
    radix = 16
    start = 1
  } else if source[0] == '#' {
    radix = 10
    start = 1
  } else if source[0] == '%' {
    radix = 2
    start = 1
  }
  if start == source.length() {
    return None
  }
  let negative = source[start] == '-'
  if negative || source[start] == '+' {
    start += 1
  }
  if start == source.length() {
    return None
  }
  let mut value = 0L
  for i in start..<source.length() {
    let digit = digit_value(source[i])
    if digit < 0 || digit >= radix {
      return None
    }
    value = value * radix.to_int64() + digit.to_int64()
    if value > (if negative { 2147483648L } else { 4294967295L }) {
      return None
    }
  }
  Some((if negative { -value } else { value }).to_int())
}

///|
fn Machine::format_integer(
  self : Machine,
  value : Int,
  unsigned : Bool,
) -> String {
  let negative = value < 0 && !unsigned
  let mut n = if unsigned {
    value.to_int64() & 4294967295L
  } else if negative {
    -value.to_int64()
  } else {
    value.to_int64()
  }
  let digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  let parts = []
  while true {
    let i = (n % self.base.to_int64()).to_int()
    parts.push(digits[i:i + 1].to_owned())
    n = n / self.base.to_int64()
    if n == 0 {
      break
    }
  }
  (if negative { "-" } else { "" }) + parts.rev().join("")
}
