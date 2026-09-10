///|
test "return stack single and pair order" {
  let m = @forth.Machine::new()
  m.eval("10 >r 20 r@ r> 30 40 2>r 2r@ 2r>")
  assert_eq(m.values(), [20, 10, 10, 30, 40, 30, 40])
}

///|
test "return stack word frames and IF" {
  let m = @forth.Machine::new()
  m.eval(": inner 8 >r r> ; : outer 3 >r inner 1 if r@ then r> ; outer")
  assert_eq(m.values(), [8, 3, 3])
}

///|
test "return stack counted loops and begin" {
  let m = @forth.Machine::new()
  m.eval(
    ": sum 0 3 0 do i >r r@ + r> drop loop ; sum 3 >r begin r> 1- dup >r 0= until r>",
  )
  assert_eq(m.values(), [3, 0])
}

///|
test "return stack underflow frame isolation and cleanup" {
  for
    source in [
      "r>", "r@", "2r>", "2r@", ">r", "1 2>r", "1 >r", ": bad r> ; 1 >r bad", "1 >r unknown",
      "1 >r begin again",
    ] {
    let m = @forth.Machine::new()
    assert_true(
      try {
        m.eval(source, budget=60)
        false
      } catch {
        _ => true
      },
    )
    assert_true(
      try {
        m.eval("r@")
        false
      } catch {
        _ => true
      },
    )
    m.eval("7 >r r>")
  }
}

///|
test "return stack bounded allocation" {
  let m = @forth.Machine::new()
  assert_true(
    try {
      m.eval("5000 0 do i >r loop", budget=30000)
      false
    } catch {
      _ => true
    },
  )
  m.eval("9 >r r>")
  assert_eq(m.values().last(), Some(9))
}
