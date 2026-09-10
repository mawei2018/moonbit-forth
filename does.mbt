///|
fn Machine::attach_does(
  self : Machine,
  tail : Array[String],
) -> Unit raise ForthError {
  if !self.in_word {
    raise Invalid("DOES> outside definition")
  }
  if self.loop_indices.length() != self.loop_base ||
    self.returns.length() != self.return_base {
    raise Invalid("DOES> requires balanced loop and return stacks")
  }
  let created = match self.latest_created {
    Some(body) => body
    None => raise Invalid("DOES> requires most recent definition from CREATE")
  }
  // Preserve the address and unique no-op identity; mutate shared references.
  while created.length() > 2 {
    ignore(created.pop())
  }
  for token in tail {
    created.push(token)
  }
  self.exiting = true
}
