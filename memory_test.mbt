///|
test "data space variables constants and persistent evaluation" {
  let m = @forth.Machine::new()
  m.eval(
    "variable count 5 count ! 3 count +! count @ 42 constant answer answer",
  )
  assert_eq(m.values(), [8, 42])
  m.eval(": increment 1 count +! ; increment count @")
  assert_eq(m.values(), [8, 42, 9])
}

///|
test "data space byte cells and little endian storage" {
  let m = @forth.Machine::new()
  m.eval("create table 16909060 , -1 , table c@ table cell+ @ 2 cells")
  assert_eq(m.values(), [4, -1, 8])
  m.eval("255 table c! table @")
  assert_eq(m.values(), [4, -1, 8, 16909311])
}

///|
test "data space allot alignment fill erase and overlapping move" {
  let m = @forth.Machine::new()
  m.eval(
    "create b 12 allot b 12 65 fill b 1 + 66 swap c! b b 2 + 8 move b 3 + c@ b 4 erase b @ here -4 allot here",
  )
  assert_eq(m.values(), [66, 0, 12, 8])
  let n = @forth.Machine::new()
  n.eval("1 c, align here 5 aligned")
  assert_eq(n.values(), [4, 8])
}

///|
test "data space rejects invalid addresses alignment and allocation" {
  for
    source in [
      "0 @", "variable a 1 @", "-1 c@", "65537 allot", "-1 allot", "create b 4 allot b 8 erase",
      "create b 4 allot b 0 8 move", "1 c, 2 ,", "variable", "1 constant",
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
  }
}
