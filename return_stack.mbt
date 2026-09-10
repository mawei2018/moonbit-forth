///|
fn Machine::execute_frame(
  self : Machine,
  code : Array[String],
  depth : Int,
  is_word : Bool,
) -> Unit raise ForthError {
  let previous_loop = self.loop_base
  let previous_word = self.in_word
  self.loop_base = self.loop_indices.length()
  self.in_word = is_word
  let previous = self.return_base
  let base = self.returns.length()
  self.return_base = base
  errdefer {
    while self.returns.length() > base {
      ignore(self.returns.pop())
    }
    self.return_base = previous
    self.loop_base = previous_loop
    self.in_word = previous_word
    self.exiting = false
  }
  self.execute(code, depth)
  if self.returns.length() != base {
    raise Invalid("unbalanced return stack at word boundary")
  }
  self.return_base = previous
  self.loop_base = previous_loop
  self.in_word = previous_word
  self.exiting = false
}

///|
fn Machine::return_word(self : Machine, word : String) -> Unit raise ForthError {
  let count = if word.has_prefix("2") { 2 } else { 1 }
  if word == ">r" || word == "2>r" {
    if self.stack.length() < count {
      raise Invalid("stack underflow")
    }
    if self.returns.length() + count > 4096 {
      raise Invalid("return stack limit exceeded")
    }
    let start = self.stack.length() - count
    for i in 0..<count {
      self.returns.push(self.stack[start + i])
    }
    for _ in 0..<count {
      ignore(self.stack.pop())
    }
  } else {
    if self.returns.length() - self.return_base < count {
      raise Invalid("return stack underflow in current word")
    }
    if self.stack.length() + count > 4096 {
      raise Invalid("stack limit exceeded")
    }
    let start = self.returns.length() - count
    for i in 0..<count {
      self.stack.push(self.returns[start + i])
    }
    if word == "r>" || word == "2r>" {
      for _ in 0..<count {
        ignore(self.returns.pop())
      }
    }
  }
}
