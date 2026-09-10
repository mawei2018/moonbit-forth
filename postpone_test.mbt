///|
test "postpone ordinary and immediate semantics" {
  let m = @forth.Machine::new()
  m.eval(
    ": old 3 ; : emit postpone old ; immediate : result emit ; : old 9 ; result : seven 7 ; immediate : delayed postpone seven ; delayed",
  )
  assert_eq(m.values(), [3, 7])
}

///|
test "postpone control aliases and literal macros" {
  let m = @forth.Machine::new()
  m.eval(
    ": endif postpone then ; immediate : otherwise postpone else ; immediate : choice if 7 otherwise 8 endif ; 1 choice 0 choice : lit7 7 postpone literal ; immediate : value lit7 ; value",
  )
  assert_eq(m.values(), [7, 8, 7])
}

///|
test "postpone builtin binding and loop generation" {
  let m = @forth.Machine::new()
  m.eval(
    ": twice postpone dup postpone + ; immediate : double twice ; : dup 99 ; 4 double : start postpone do ; immediate : finish postpone loop ; immediate : indices 3 0 start i finish ; indices",
  )
  assert_eq(m.values(), [8, 0, 1, 2])
}

///|
test "postpone does behavior generation" {
  let m = @forth.Machine::new()
  m.eval(
    ": behavior postpone does> ; immediate : con create , behavior @ ; 8 con x x",
  )
  assert_eq(m.values(), [8])
}

///|
test "postpone rejects malformed generated definitions" {
  for
    source in [
      ": bad postpone ;", ": bad postpone missing ;", ": bad postpone if ; immediate : broken bad ;",
      ": bad postpone then ; immediate : broken bad ;", ": bad postpone literal ; bad",
    ] {
    let m = @forth.Machine::new()
    assert_true(
      try {
        m.eval(source)
        false
      } catch {
        _ => true
      },
    )
    m.eval(": good 8 ; good")
    assert_eq(m.values(), [8])
  }
}
