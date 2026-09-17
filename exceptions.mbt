///|
fn exception_code(error : ForthError) -> Int {
  match error {
    Thrown(code) => code
    Invalid(message) =>
      if message.contains("stack underflow") {
        -4
      } else if message.contains("division") {
        -10
      } else if message.contains("unknown") {
        -13
      } else if message.contains("unaligned") {
        -23
      } else if message.contains("data space range") ||
        message.contains("execution token") {
        -9
      } else {
        -256
      }
  }
}

///|
pub fn ForthError::code(self : ForthError) -> Int {
  exception_code(self)
}

///|
fn Machine::catch_word(self : Machine, depth : Int) -> Unit raise ForthError {
  let xt = self.pop()
  if xt < 1 || xt > self.execution_tokens.length() {
    raise Invalid("invalid execution token")
  }
  let saved = self.stack.copy()
  let old_leaving = self.leaving
  self.catch_depth += 1
  defer {
    self.catch_depth -= 1
  }
  let result = try {
    self.execute_frame(self.execution_tokens[xt - 1], depth + 1, true)
    0
  } catch {
    error => exception_code(error)
  }
  if result != 0 {
    self.stack.clear()
    for value in saved {
      self.stack.push(value)
    }
    self.leaving = old_leaving
  }
  self.stack.push(result)
}
