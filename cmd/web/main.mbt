///|
pub fn run(input : String) -> String {
  try {
    let m = @lib.Machine::new()
    m.eval(input, budget=20000)
    "Output: " + m.printed() + "\nStack: " + Repr(m.values()).to_string()
  } catch {
    e => "ERROR: " + Repr(e).to_string()
  }
}

///|
fn main {

}
