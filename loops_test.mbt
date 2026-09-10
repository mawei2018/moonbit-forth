///|
test "begin loops until consumes flag and preserves body results" {
  let m = @forth.Machine::new()
  m.eval("0 begin 1+ dup 4 = until")
  assert_eq(m.values(), [4])
  let n = @forth.Machine::new()
  n.eval(": countdown begin 1- dup 0= until ; 3 countdown")
  assert_eq(n.values(), [0])
}

///|
test "begin loops while repeat skips body when initial condition is false" {
  let m = @forth.Machine::new()
  m.eval("0 begin dup 0> while 1- repeat 3 begin dup 0> while 1- repeat")
  assert_eq(m.values(), [0, 0])
}

///|
test "begin loops nested loops variables and conditional branches" {
  let m = @forth.Machine::new()
  m.eval(
    "variable outer variable inner 0 outer ! begin 0 inner ! begin 1 inner +! inner @ 2 = until 1 outer +! outer @ 3 = until outer @ inner @",
  )
  assert_eq(m.values(), [3, 2])
  m.eval("0 begin 1+ dup 2 > if -1 else 0 then until")
  assert_eq(m.values(), [3, 2, 3])
}

///|
test "begin loops malformed control and empty infinite loop are bounded" {
  for
    source in [
      "begin again", "begin", "while", "repeat", "until", "begin 1 while 2 until",
      "begin 1 repeat", "begin 1 while 2 while 3 repeat", "begin until",
    ] {
    let m = @forth.Machine::new()
    assert_true(
      try {
        m.eval(source, budget=50)
        false
      } catch {
        _ => true
      },
    )
  }
}
