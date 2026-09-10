///|
fn Machine::capture_xt(self : Machine, name : String) -> Int raise ForthError {
  let body = match self.words.get(name) {
    Some(body) => body
    None => {
      if !primitive_word(name) ||
        [
          "exit", "unloop", "leave", "i", "j", ">r", "r>", "r@", "2>r", "2r>", "2r@",
        ].contains(name) {
        raise Invalid("word has no supported execution token: " + name)
      }
      ["\u0001" + name]
    }
  }
  for i in 0..<self.execution_tokens.length() {
    if self.execution_tokens[i] == body {
      return i + 1
    }
  }
  if self.execution_tokens.length() >= 65536 {
    raise Invalid("execution token limit exceeded")
  }
  self.execution_tokens.push(body)
  self.execution_tokens.length()
}
