///|
test "compile evaluation arithmetic literal and prior word" {
  let m = @forth.Machine::new()
  m.eval(": square dup * ; : value [ 7 square 2 + ] literal ; value value")
  assert_eq(m.values(), [51, 51])
}

///|
test "compile evaluation side effects happen once" {
  let m = @forth.Machine::new()
  m.eval("variable n : value [ 1 n +! n @ ] literal ; value value n @")
  assert_eq(m.values(), [1, 1, 1])
}

///|
test "compile evaluation tick callbacks and resume outer source" {
  let m = @forth.Machine::new()
  m.eval(
    ": run [ ' dup ] literal execute + ; 5 run :noname [ 8 3 + ] literal ; execute 9",
  )
  assert_eq(m.values(), [10, 11, 9])
}

///|
test "compile evaluation within control and does" {
  let m = @forth.Machine::new()
  m.eval(
    ": choice if [ 2 3 * ] literal else [ 4 5 + ] literal then ; 1 choice 0 choice : maker create , does> @ [ 3 2 + ] literal + ; 7 maker item item",
  )
  assert_eq(m.values(), [6, 9, 12])
}

///|
test "compile evaluation errors restore modes and budget" {
  for
    source in [
      ": bad [ 3 ;", ": bad ] ;", ": bad [ [ 3 ] ] ;", ": bad literal ;", ": bad [ 1 0 / ] literal ;",
      ": bad [ begin again ] ;", ": bad [ variable x ] ;",
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
    m.eval("variable restored : good [ 3 4 + ] literal ; good")
    assert_eq(m.values(), [7])
  }
}
