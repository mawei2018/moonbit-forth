///|
fn Machine::binding_key(self : Machine) -> String raise ForthError {
  if self.binding_id >= 65536 {
    raise Invalid("compiled binding limit exceeded")
  }
  let key = "\u0000" + self.binding_id.to_string()
  self.binding_id += 1
  key
}

///|
fn primitive_word(word : String) -> Bool {
  text_primitive(word) ||
  [
    "dup", "drop", "swap", "over", "rot", "nip", "tuck", "2dup", "2drop", "2swap",
    "here", "allot", "align", "aligned", "cells", "cell+", "@", "c@", "!", "c!",
    "+!", ",", "c,", "fill", "erase", "move", "0=", "0<", "0>", "1+", "1-", "i",
    "j", "exit", "unloop", "leave", ">r", "r>", "r@", "2>r", "2r>", "2r@", "depth",
    ".", "negate", "+", "-", "*", "/", "mod", "=", "<", ">", "and", "or", "execute",
    "variable", "constant", "create", "'", ">body", "immediate", "compile,", "state",
    "abs", "min", "max", "/mod", "*/", "*/mod", "2*", "2/", "invert", "xor", "lshift",
    "rshift", "u<", "u>", "within", "<>", "0<>",
  ].contains(word)
}
