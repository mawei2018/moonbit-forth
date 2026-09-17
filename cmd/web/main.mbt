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

///|
pub fn report(input : String) -> String {
  let machine = @lib.Machine::new()
  let result : Map[String, Json] = Map([])
  try {
    machine.eval(input, budget=1000000)
    result["ok"] = true.to_json()
  } catch {
    error => {
      result["ok"] = false.to_json()
      result["error"] = Json::string(Repr(error).to_string())
      result["code"] = error.code().to_json()
    }
  }
  result["stack"] = machine.values().to_json()
  result["output"] = Json::string(machine.output_text())
  result["bytes"] = machine
    .output_bytes()
    .to_array()
    .map(byte => byte.to_int())
    .to_json()
  result.to_json().stringify()
}
