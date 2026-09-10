///|
test "binding preserves user words constants and variables" {
  let m = @forth.Machine::new()
  m.eval(
    ": a 3 ; : b a ; : a 9 ; b a 7 constant c : saved c ; 8 constant c saved c variable v 4 v ! : get v @ ; variable v 5 v ! get v @",
  )
  assert_eq(m.values(), [3, 9, 7, 8, 4, 5])
}

///|
test "binding preserves primitive and previous same name" {
  let m = @forth.Machine::new()
  m.eval(": old dup ; : dup 99 ; 2 old dup : a 1 ; : a a 1+ ; a")
  assert_eq(m.values(), [2, 2, 99, 2])
}

///|
test "binding recurse retains identity after redefinition" {
  let m = @forth.Machine::new()
  m.eval(
    ": factorial dup 2 < if drop 1 exit then dup 1- recurse * ; : saved factorial ; : factorial 99 ; 5 saved factorial",
  )
  assert_eq(m.values(), [120, 99])
}

///|
test "binding recursive return stack" {
  let m = @forth.Machine::new()
  m.eval(": walk dup if dup >r 1- recurse r> then ; 3 walk")
  assert_eq(m.values(), [0, 1, 2, 3])
}

///|
test "binding failed definition keeps prior version" {
  let m = @forth.Machine::new()
  m.eval(": a 8 ;")
  assert_true(
    try {
      m.eval(": a missing ;")
      false
    } catch {
      _ => true
    },
  )
  m.eval("a")
  assert_eq(m.values(), [8])
  assert_true(
    try {
      m.eval(": forever recurse ; forever", budget=100)
      false
    } catch {
      _ => true
    },
  )
  m.eval("a")
  assert_eq(m.values(), [8, 8])
}
