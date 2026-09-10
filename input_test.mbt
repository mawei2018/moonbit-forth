///|
test "runtime names defining variable constant and create" {
  let m = @forth.Machine::new()
  m.eval(
    ": var variable ; var count 6 count ! count @ : con constant ; 9 con answer answer : table create 10 , 20 , ; table data data @ data cell+ @",
  )
  assert_eq(m.values(), [6, 9, 10, 20])
}

///|
test "runtime names nested and multiple consumers" {
  let m = @forth.Machine::new()
  m.eval(
    ": get ' ; : call get execute ; 3 call dup + : pair variable variable ; pair a b 1 a ! 2 b ! a @ b @",
  )
  assert_eq(m.values(), [6, 1, 2])
}

///|
test "runtime names condition and counted loop" {
  let m = @forth.Machine::new()
  m.eval(
    ": maybe if variable then ; 1 maybe yes 0 maybe 7 : several 2 0 do variable loop ; several a b 3 a ! 4 b ! a @ b @",
  )
  assert_eq(m.values(), [7, 3, 4])
}

///|
test "runtime names execute parsing primitive" {
  let m = @forth.Machine::new()
  m.eval("' variable execute box 5 box ! box @ ' ' execute dup 8 swap execute")
  assert_eq(m.values(), [5, 8, 8])
}

///|
test "runtime names failure resets source" {
  let m = @forth.Machine::new()
  m.eval(": make variable ; : get ' ;")
  for source in ["make", "get", "make 12", "get missing"] {
    assert_true(
      try {
        m.eval(source)
        false
      } catch {
        _ => true
      },
    )
  }
  m.eval("make fresh 7 fresh ! fresh @")
  assert_eq(m.values(), [7])
}
