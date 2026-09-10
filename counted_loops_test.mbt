///|
test "counted loops normal skip and nested indices" {
  let m = @forth.Machine::new()
  m.eval("3 0 do i loop 4 4 ?do 99 loop 2 0 do 2 0 do j i loop loop")
  assert_eq(m.values(), [0, 1, 2, 0, 0, 0, 1, 1, 0, 1, 1])
}

///|
test "counted loops positive negative and crossing increments" {
  let m = @forth.Machine::new()
  m.eval("5 0 do i 2 +loop 0 3 do i -1 +loop")
  assert_eq(m.values(), [0, 2, 4, 3, 2, 1, 0])
  let n = @forth.Machine::new()
  n.eval("-2147483647 2147483646 do i loop")
  assert_eq(n.values(), [2147483646, 2147483647, -2147483648])
}

///|
test "counted loops leave propagates through IF BEGIN and nested loops" {
  let m = @forth.Machine::new()
  m.eval("9 0 do i dup 2 = if leave then loop")
  assert_eq(m.values(), [0, 1, 2])
  let n = @forth.Machine::new()
  n.eval("2 0 do 5 0 do i leave loop i loop")
  assert_eq(n.values(), [0, 0, 0, 1])
}

///|
test "counted loops leave in begin and failure cleanup" {
  let m = @forth.Machine::new()
  m.eval("3 0 do begin i leave again 99 loop 7")
  assert_eq(m.values(), [0, 7])
  for
    source in [
      "i", "j", "leave", "loop", "1 0 do", "0 0 do loop", "1 0 do 0 +loop",
    ] {
    let n = @forth.Machine::new()
    assert_true(
      try {
        n.eval(source, budget=50)
        false
      } catch {
        _ => true
      },
    )
    assert_true(
      try {
        n.eval("i")
        false
      } catch {
        _ => true
      },
    )
    n.eval("2 0 do i loop")
  }
}
