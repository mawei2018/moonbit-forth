///|
fn control_word(word : String) -> Bool {
  [
    "if", "else", "then", "begin", "while", "repeat", "until", "again", "do", "?do",
    "loop", "+loop",
  ].contains(word)
}

///|
fn Machine::postpone_into(
  self : Machine,
  name : String,
  output : Array[String],
) -> Unit raise ForthError {
  if self.words.get(name) is Some(_) {
    let xt = self.capture_xt(name)
    output.push(xt.to_string())
    output.push(
      if self.immediate_words.get(name) == Some(true) {
        "\u0001execute"
      } else {
        "\u0001compile,"
      },
    )
  } else if control_word(name) ||
    primitive_word(name) ||
    name == "literal" ||
    name == "does>" {
    output.push("\u0002" + name)
  } else {
    raise Invalid("unsupported POSTPONE target: " + name)
  }
}

///|
fn Machine::emit_postponed(
  self : Machine,
  name : String,
) -> Unit raise ForthError {
  let output = match self.compile_output {
    Some(output) => output
    None => raise Invalid("postponed compilation outside definition")
  }
  if output.length() >= 65536 {
    raise Invalid("compiled definition limit")
  }
  if name == "literal" {
    output.push(self.pop().to_string())
  } else if control_word(name) {
    output.push(name)
  } else {
    output.push("\u0001" + name)
  }
}
