///|
test "does constant builders and independent data" {
  let m = @forth.Machine::new()
  m.eval(": con create , does> @ ; 7 con a 9 con b a b")
  assert_eq(m.values(), [7, 9])
}

///|
test "does array builder and conditional behavior" {
  let m = @forth.Machine::new()
  m.eval(
    ": array create cells allot does> swap cells + ; 3 array table 42 1 table ! 1 table @ : flag create , does> @ if 8 else 9 then ; 0 flag no 1 flag yes no yes",
  )
  assert_eq(m.values(), [42, 9, 8])
}

///|
test "does helper and repeated behavior replacement" {
  let m = @forth.Machine::new()
  m.eval(
    ": make create , ; : plusone does> @ 1+ ; : plustwo does> @ 2 + ; 5 make a plusone a plustwo a",
  )
  assert_eq(m.values(), [6, 7])
}

///|
test "does token identity and self replacing body" {
  let m = @forth.Machine::new()
  m.eval(
    ": change does> drop 7 ; create a ' a create b ' b change execute swap execute",
  )
  assert_eq(m.values(), [7, 0])
  let n = @forth.Machine::new()
  n.eval(": weird create does> 1+ does> 2 + ; weird a a a")
  assert_eq(n.values(), [1, 2])
}

///|
test "does invalid context and recovery" {
  for
    source in [
      "does>", ": bad does> @ ; bad", ": bad create 1 >r does> @ ; bad x", ": bad 1 if does> then ;",
      ": bad create does> recurse ;",
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
    m.eval(": good create , does> @ ; 6 good ok ok")
    assert_eq(m.values(), [6])
  }
}
