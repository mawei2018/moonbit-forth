///|
fn Machine::runtime_name(
  self : Machine,
  _code : Array[String],
  pc : Int,
  _depth : Int,
) -> (String, Int) raise ForthError {
  (self.source_name().to_lower(), pc)
}
