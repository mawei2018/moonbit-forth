///|
test "compile structure rejects unreachable malformed controls" {
  for
    body in [
      "if", "begin", "do", "?do", "else", "then", "while", "repeat", "until", "again",
      "loop", "+loop", "if else else then", "begin while until", "begin repeat",
      "if loop", "do then", "begin if until then", "if do then loop", "begin while while repeat",
      "if does> then", "begin does> again",
    ] {
    let m = @forth.Machine::new()
    m.eval(": existing 9 ;")
    assert_true(
      try {
        m.eval(": existing " + body + " ;")
        false
      } catch {
        _ => true
      },
    )
    m.eval("existing")
    assert_eq(m.values(), [9])
  }
}

///|
test "compile structure mixed nesting and does sections" {
  let m = @forth.Machine::new()
  m.eval(
    ": mixed 2 0 do i if 2 begin 1- dup 0= until else 7 then loop ; mixed : maker create , does> @ if 4 else 5 then ; 0 maker x x",
  )
  assert_eq(m.values(), [7, 0, 5])
}

///|
test "compile structure recursion and anonymous forms" {
  let m = @forth.Machine::new()
  m.eval(":noname dup if 1- recurse then ; 3 swap execute")
  assert_eq(m.values(), [0])
  assert_true(
    try {
      m.eval(":noname 0 if ;")
      false
    } catch {
      _ => true
    },
  )
  m.eval(":noname 6 ; execute")
  assert_eq(m.values(), [0, 6])
}

///|
test "compile structure failed captures preserve existing tokens" {
  let m = @forth.Machine::new()
  m.eval(": old 3 ; ' old constant saved")
  for _ in 0..<100 {
    assert_true(
      try {
        m.eval(": broken old ['] dup missing ;")
        false
      } catch {
        _ => true
      },
    )
  }
  m.eval("saved execute 4 ' dup execute")
  assert_eq(m.values(), [3, 4, 4])
}
