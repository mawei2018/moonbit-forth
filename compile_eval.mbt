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
