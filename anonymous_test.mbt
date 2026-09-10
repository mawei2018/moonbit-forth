///|
test "anonymous callback storage and execution" {
  let m = @forth.Machine::new()
  m.eval(
    ":noname dup * ; constant square 7 square execute variable cb :noname 1+ ; cb ! 5 cb @ execute",
  )
  assert_eq(m.values(), [49, 6])
}

///|
test "anonymous recurse and does builder" {
  let m = @forth.Machine::new()
  m.eval(
    ":noname dup 2 < if drop 1 exit then dup 1- recurse * ; constant fact 5 fact execute :noname create , does> @ ; 8 swap execute eight eight",
  )
  assert_eq(m.values(), [120, 8])
}

///|
test "anonymous body address survives does and redefine" {
  let m = @forth.Machine::new()
  m.eval(
    ": con create , does> @ ; 4 con a ' a dup >body 7 swap ! execute ' a : a 99 ; >body @ a",
  )
  assert_eq(m.values(), [7, 7, 99])
}

///|
test "anonymous body address before allocation" {
  let m = @forth.Machine::new()
  m.eval("create data ' data >body here = 6 , ' data >body @")
  assert_eq(m.values(), [-1, 6])
}

///|
test "anonymous invalid forms and nondata tokens" {
  for
    source in [
      ":noname", ":noname :noname ; ;", ":noname missing ;", "0 >body", "' dup >body",
      ":noname 1 ; >body", "5 constant c ' c >body",
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
    m.eval(":noname 8 ; execute")
    assert_eq(m.values(), [8])
  }
}
