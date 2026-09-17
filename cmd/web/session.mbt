///|
let machines : Map[Int, @lib.Machine] = Map([])

///|
let next_id : Ref[Int] = Ref(1)

///|
fn result(machine : @lib.Machine) -> Map[String, Json] {
  Map([
    ("ok", true.to_json()),
    ("stack", machine.values().to_json()),
    ("output", Json::string(machine.output_text())),
    (
      "bytes",
      machine.output_bytes().to_array().map(byte => byte.to_int()).to_json(),
    ),
    ("compiling", machine.is_compiling().to_json()),
  ])
}

///|
pub fn session(request : String) -> String {
  let response : Map[String, Json] = Map([])
  try {
    if request.length() > 2200000 {
      fail("session request size limit")
    }
    guard @json.parse(request) is Object(fields) else {
      fail("session object required")
    }
    guard fields.get("op") is Some(String(op)) else {
      fail("op string required")
    }
    let allowed = match op {
      "open" => ["op"]
      "eval" | "feed" => ["op", "id", "source", "budget"]
      "state" | "reset" | "close" => ["op", "id"]
      _ => fail("unknown session operation")
    }
    for key, _ in fields {
      if !allowed.contains(key) {
        fail("unknown session option: " + key)
      }
    }
    if op == "open" {
      if machines.length() >= 8 || next_id.val >= 1000000000 {
        fail("session limit")
      }
      let id = next_id.val
      next_id.val += 1
      machines[id] = @lib.Machine::new()
      return Map([("ok", true.to_json()), ("id", id.to_json())])
        .to_json()
        .stringify()
    }
    let id : Int = @json.from_json(fields.get("id").unwrap_or(Json::null()))
    guard machines.get(id) is Some(machine) else { fail("unknown session") }
    if op == "close" {
      machines.remove(id)
      return "{\"ok\":true}"
    }
    if op == "reset" {
      let replacement = @lib.Machine::new()
      machines[id] = replacement
      return result(replacement).to_json().stringify()
    }
    if op == "state" {
      return result(machine).to_json().stringify()
    }
    guard fields.get("source") is Some(String(source)) else {
      fail("source string required")
    }
    let budget : Int = @json.from_json(
      fields.get("budget").unwrap_or(Json::number(1000000)),
    )
    if budget < 1 || budget > 10000000 {
      fail("budget must be 1..10000000")
    }
    machine.clear_output()
    let error = try {
      if op == "feed" {
        ignore(machine.feed(source, budget~))
      } else {
        machine.eval(source, budget~)
      }
      None
    } catch {
      error => Some(error)
    }
    let response = result(machine)
    if error is Some(error) {
      response["ok"] = false.to_json()
      response["code"] = error.code().to_json()
      response["error"] = Json::string(Repr(error).to_string())
    }
    response.to_json().stringify()
  } catch {
    error => {
      response["ok"] = false.to_json()
      response["error"] = Json::string(Repr(error).to_string())
      response["host_error"] = true.to_json()
      response.to_json().stringify()
    }
  }
}
