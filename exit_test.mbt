///|
test "word exit conditional and begin" {
  let m = @forth.Machine::new()
  m.eval(
    ": choose dup 0= if drop 7 exit then 1+ ; 0 choose 4 choose : spin begin 8 exit again 99 ; spin 10",
  )
  assert_eq(m.values(), [7, 5, 8, 10])
}

///|
test "word exit nested calls preserve caller loops and returns" {
  let m = @forth.Machine::new()
  m.eval(": inner 4 exit 99 ; : outer 9 >r 2 0 do inner i loop r> ; outer")
  assert_eq(m.values(), [4, 0, 4, 1, 9])
}

///|
test "word exit unloop nested loops" {
  let m = @forth.Machine::new()
  m.eval(
    ": search 5 0 do i dup 2 = if unloop exit then loop 99 ; search 7 : nested 3 0 do 4 0 do j i unloop unloop exit loop loop ; nested 8",
  )
  assert_eq(m.values(), [0, 1, 2, 7, 0, 0, 8])
}

///|
test "word exit invalid cleanup" {
  for
    source in [
      "exit", "unloop", ": bad 2 0 do exit loop ; bad", ": bad 2 0 do unloop loop ; bad",
      ": bad 1 >r exit ; bad", ": bad unloop ; 2 0 do bad loop", ": bad 2 0 do 2 0 do unloop exit loop loop ; bad",
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
    m.eval(": good 6 exit 99 ; good 2 0 do i loop")
    assert_eq(m.values(), [6, 0, 1])
  }
}
