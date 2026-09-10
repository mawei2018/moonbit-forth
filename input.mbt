///|
fn Machine::runtime_name(
  self : Machine,
  code : Array[String],
  pc : Int,
  depth : Int,
) -> (String, Int) raise ForthError {
  if depth == 0 {
    if pc >= code.length() {
      raise Invalid("missing input name")
    }
    self.input_pc = pc + 1
    (code[pc], pc + 1)
  } else {
    if self.input_pc >= self.input.length() {
      raise Invalid("missing input name")
    }
    let name = self.input[self.input_pc]
    self.input_pc += 1
    (name, pc)
  }
}
