///|
test "compiler state interpretation immediate and brackets" {
  let m = @forth.Machine::new()
  m.eval(
    "state @ : mode state @ ; immediate : compiled mode literal ; : interpreted [ mode ] literal ; compiled interpreted mode state @",
  )
  assert_eq(m.values(), [0, -1, 0, 0, 0])
}

///|
test "compiler state aware literal macro" {
  let m = @forth.Machine::new()
  m.eval(
    ": smart 7 state @ if postpone literal then ; immediate smart : value smart ; value",
  )
  assert_eq(m.values(), [7, 7])
}

///|
test "compiler state postponed bracket tick parses later name" {
  let m = @forth.Machine::new()
  m.eval(
    ": quote postpone ['] ; immediate : callback quote dup ; 4 callback execute +",
  )
  assert_eq(m.values(), [8])
}

///|
test "compiler state recovery and read only cell" {
  let m = @forth.Machine::new()
  m.eval(": mode state @ ; immediate")
  for
    source in [
      ": broken mode [ drop ] missing ;", ": broken [ 1 0 / ] ;", "1 state !", "1 state c!",
    ] {
    assert_true(
      try {
        m.eval(source)
        false
      } catch {
        _ => true
      },
    )
    m.eval("state @")
  }
  assert_eq(m.values(), [0, 0, 0, 0])
  m.eval(": good mode literal ; good")
  assert_eq(m.values(), [0, 0, 0, 0, -1])
}
