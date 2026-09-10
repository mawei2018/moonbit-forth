///|
fn validate_structure(body : Array[String]) -> Unit raise ForthError {
  let scopes : Array[String] = []
  let mut pc = 0
  while pc < body.length() {
    let word = body[pc]
    pc += 1
    if word == "[" {
      let (_, next) = bracket_chunk(body, pc)
      pc = next
      continue
    }
    if word == "]" {
      raise Invalid("unexpected closing bracket")
    }
    if word == "[']" {
      if pc >= body.length() {
        raise Invalid("missing execution token name")
      }
      pc += 1
      continue
    }
    match word {
      "if" | "begin" | "do" | "?do" => {
        if scopes.length() >= 64 {
          raise Invalid("control nesting limit")
        }
        scopes.push(if word == "?do" { "do" } else { word })
      }
      "else" => {
        if scopes.pop() != Some("if") {
          raise Invalid("ELSE without matching IF")
        }
        scopes.push("else")
      }
      "then" => {
        let open = scopes.pop()
        if open != Some("if") && open != Some("else") {
          raise Invalid("THEN without matching IF")
        }
      }
      "while" => {
        if scopes.pop() != Some("begin") {
          raise Invalid("WHILE without matching BEGIN")
        }
        scopes.push("while")
      }
      "repeat" =>
        if scopes.pop() != Some("while") {
          raise Invalid("REPEAT without matching WHILE")
        }
      "until" | "again" =>
        if scopes.pop() != Some("begin") {
          raise Invalid("UNTIL/AGAIN without matching BEGIN")
        }
      "loop" | "+loop" =>
        if scopes.pop() != Some("do") {
          raise Invalid("LOOP without matching DO")
        }
      "does>" =>
        if !scopes.is_empty() {
          raise Invalid("DOES> inside control structure")
        }
      _ => ()
    }
  }
  if !scopes.is_empty() {
    raise Invalid("unclosed control structure in definition")
  }
}
