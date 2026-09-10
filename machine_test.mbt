///|
test "definition and case insensitive execution" {
  let m = @forth.Machine::new()
  m.eval(": square dup * ; 7 SQUARE 2 +")
  assert_eq(m.values(), [51])
}

///|
test "nested conditionals and output" {
  let m = @forth.Machine::new()
  m.eval("1 if 0 if 10 else 20 then else 30 then .")
  assert_eq(m.printed(), "20")
  assert_eq(m.values(), [])
}

///|
test "stack and comments" {
  let m = @forth.Machine::new()
  m.eval("1 2 3 rot ( comment ) over + swap \\ ignored\n depth")
  assert_eq(m.values(), [2, 4, 3, 3])
}

///|
test "invalid programs are explicit errors" {
  for
    source in [
      "drop", "1 0 /", "1 if 2", ": x 1", "unknown", "( unclosed", "then", "1 if 2 else 3 else 4 then",
    ] {
    let failed = try {
      @forth.Machine::new().eval(source)
      false
    } catch {
      _ => true
    }
    assert_true(failed)
  }
}

///|
test "budget and recursive call limit" {
  let m = @forth.Machine::new()
  let exhausted = try {
    m.eval("1 2 3", budget=2)
    false
  } catch {
    _ => true
  }
  assert_true(exhausted)
  let recursive = try {
    m.eval(": loop loop ; loop")
    false
  } catch {
    _ => true
  }
  assert_true(recursive)
}

///|
test "negative integer and comparison" {
  let m = @forth.Machine::new()
  m.eval("-7 3 / -2 = 9 2 mod")
  assert_eq(m.values(), [-1, 1])
}
