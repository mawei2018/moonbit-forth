///|
fn begin_body(
  code : Array[String],
  start : Int,
) -> (Array[String], Array[String], String, Int) raise ForthError {
  let body = []
  let tail = []
  let mut nesting = 1
  let mut after_while = false
  let mut pc = start
  while pc < code.length() {
    let word = code[pc]
    pc += 1
    if word == "begin" {
      nesting += 1
    }
    if ["until", "again", "repeat"].contains(word) {
      nesting -= 1
      if nesting == 0 {
        if (word == "repeat") != after_while {
          raise Invalid("WHILE requires REPEAT; UNTIL/AGAIN require no WHILE")
        }
        return (body, tail, word, pc)
      }
    }
    if word == "while" && nesting == 1 {
      if after_while {
        raise Invalid("multiple WHILE clauses not implemented")
      }
      after_while = true
    } else if after_while {
      tail.push(word)
    } else {
      body.push(word)
    }
  }
  raise Invalid("unterminated BEGIN loop")
}
