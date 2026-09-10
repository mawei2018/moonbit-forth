///|
test "immediate compile execution and runtime interpretation" {
  let m = @forth.Machine::new()
  m.eval(
    ": seven 7 ; immediate : value seven literal ; value seven 9 constant nine immediate : other nine literal ; other",
  )
  assert_eq(m.values(), [7, 7, 9])
}

///|
test "immediate compile comma emits bound callback" {
  let m = @forth.Machine::new()
  m.eval(
    ": emitdup ['] dup compile, ; immediate : double emitdup + ; : dup 99 ; 6 double",
  )
  assert_eq(m.values(), [12])
}

///|
test "immediate parsing macro consumes source" {
  let m = @forth.Machine::new()
  m.eval(
    ": emit ' compile, ; immediate : value 5 emit 1+ ; value : emit 8 ; : normal emit ; normal",
  )
  assert_eq(m.values(), [6, 8])
}

///|
test "immediate side effects run once and bracket compile comma" {
  let m = @forth.Machine::new()
  m.eval(
    "variable n : bump 1 n +! ; immediate : value bump 7 ; value value n @ : twice [ ' dup compile, ] + ; 4 twice",
  )
  assert_eq(m.values(), [7, 7, 1, 8])
}

///|
test "immediate errors restore compilation context" {
  for
    source in [
      "immediate", "0 compile,", ":noname 3 ; drop immediate", ": bad 0 compile, ; immediate : target bad ;",
      ": forever begin again ; immediate : target forever ;",
    ] {
    let m = @forth.Machine::new()
    assert_true(
      try {
        m.eval(source, budget=100)
        false
      } catch {
        _ => true
      },
    )
    m.eval(": good 8 ; good")
    assert_eq(m.values(), if source == "0 compile," { [0, 8] } else { [8] })
    assert_true(
      try {
        m.eval("compile,")
        false
      } catch {
        _ => true
      },
    )
  }
}
