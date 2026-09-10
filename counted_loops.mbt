///|
fn counted_body(
  code : Array[String],
  start : Int,
) -> (Array[String], Bool, Int) raise ForthError {
  let body = []
  let mut nesting = 1
  let mut pc = start
  while pc < code.length() {
    let word = code[pc]
    pc += 1
    if word == "do" || word == "?do" {
      nesting += 1
    }
    if word == "loop" || word == "+loop" {
      nesting -= 1
      if nesting == 0 {
        return (body, word == "+loop", pc)
      }
    }
    body.push(word)
  }
  raise Invalid("unterminated counted loop")
}

///|
fn Machine::counted_loop(
  self : Machine,
  body : Array[String],
  start : Int,
  limit : Int,
  plus : Bool,
  depth : Int,
) -> Unit raise ForthError {
  if self.loop_indices.length() >= 64 {
    raise Invalid("loop nesting limit")
  }
  self.loop_indices.push(start)
  errdefer {
    ignore(self.loop_indices.pop())
    self.leaving = false
  }
  while true {
    self.fuel -= 1
    if self.fuel < 0 {
      raise Invalid("execution budget exhausted")
    }
    self.execute(body, depth)
    if self.leaving {
      self.leaving = false
      break
    }
    let step = if plus { self.pop() } else { 1 }
    let at = self.loop_indices.length() - 1
    let current = self.loop_indices[at]
    let crossed = if step > 0 {
      let distance = (limit - current).reinterpret_as_uint().to_uint64()
      distance != 0UL && distance <= step.to_uint64()
    } else if step < 0 {
      let distance = (current - limit).reinterpret_as_uint().to_uint64()
      distance < (-step.to_int64()).reinterpret_as_uint64()
    } else {
      false
    }
    if crossed {
      break
    }
    self.loop_indices[at] = current + step
  }
  ignore(self.loop_indices.pop())
}
