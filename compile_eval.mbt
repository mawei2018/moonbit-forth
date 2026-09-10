///|
fn bracket_chunk(
  body : Array[String],
  start : Int,
) -> (Array[String], Int) raise ForthError {
  let chunk = []
  let mut pc = start
  while pc < body.length() {
    let word = body[pc]
    pc += 1
    if word == "]" {
      return (chunk, pc)
    }
    if word == "[" {
      raise Invalid("nested interpretation bracket")
    }
    chunk.push(word)
  }
  raise Invalid("missing closing bracket")
}

///|
fn Machine::interpret_compile_chunk(
  self : Machine,
  chunk : Array[String],
) -> Unit raise ForthError {
  let saved_input = self.input
  let saved_pc = self.input_pc
  let saved_mode = self.compile_eval
  self.input = chunk
  self.input_pc = 0
  self.compile_eval = true
  defer {
    self.input = saved_input
    self.input_pc = saved_pc
    self.compile_eval = saved_mode
  }
  self.execute_frame(chunk, 0, false)
}
