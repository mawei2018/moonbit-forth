///|
fn main raise {
  let m = @lib.Machine::new()
  m.eval(": square dup * ; 12 square . 5 3 > if 99 else 0 then .")
  println(m.printed())
}
