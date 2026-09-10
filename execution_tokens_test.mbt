///|
test "execution tokens primitive callback and identity" {
  let m = @forth.Machine::new()
  m.eval("3 ' dup execute + ' dup ' dup = : apply execute ; 6 ' 1+ apply")
  assert_eq(m.values(), [6, -1, 7])
}

///|
test "execution tokens persist across redefine and eval" {
  let m = @forth.Machine::new()
  m.eval(": a 4 ; ' a constant saved : a 8 ;")
  m.eval("saved execute a variable slot ' a slot ! slot @ execute")
  assert_eq(m.values(), [4, 8, 8])
}

///|
test "execution tokens bracket tick captures at compile time" {
  let m = @forth.Machine::new()
  m.eval(
    ": a 9 ; : callback ['] a ; : a 2 ; callback execute : double ['] dup execute + ; 7 double",
  )
  assert_eq(m.values(), [9, 14])
}

///|
test "execution tokens recursive and exit frames" {
  let m = @forth.Machine::new()
  m.eval(
    ": fact dup 2 < if drop 1 exit then dup 1- recurse * ; 4 ' fact execute 7",
  )
  assert_eq(m.values(), [24, 7])
}

///|
test "execution tokens rejected inputs recover" {
  for
    source in [
      "'", "' missing", "' 12", "' if", "' exit", "execute", "0 execute", "-1 execute",
      "65537 execute", "['] dup", ": bad ['] ;",
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
    m.eval("5 ' 1+ execute")
    assert_eq(m.values(), [6])
  }
}
