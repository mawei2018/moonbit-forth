///|
test "integer extension signed arithmetic and rounding" {
  let m = @forth.Machine::new()
  m.eval("-7 abs -7 2/ -7 3 /mod 7 -3 /mod -9 4 min -9 4 max")
  assert_eq(m.values(), [7, -4, -1, -2, 1, -2, -9, 4])
}

///|
test "integer extension wide intermediate multiply divide" {
  let m = @forth.Machine::new()
  m.eval("100000 100000 100000 */ 100000 100001 300000 */mod -7 5 3 */mod")
  assert_eq(m.values(), [100000, 200000, 33333, -2, -11])
}

///|
test "integer extension logical and arithmetic shifts" {
  let m = @forth.Machine::new()
  m.eval(
    "0 invert 5 3 xor -1 1 rshift 1 31 lshift 1073741824 2* -2147483648 abs 0 0<> 2 3 <>",
  )
  assert_eq(m.values(), [
    -1, 6, 2147483647, -2147483648, -2147483648, -2147483648, 0, -1,
  ])
}

///|
test "integer extension unsigned comparisons and wrapping interval" {
  let m = @forth.Machine::new()
  m.eval(
    "-1 1 u> -1 1 u< 0 -2 2 within 2 -2 2 within -2 -2 2 within 4 4 4 within",
  )
  assert_eq(m.values(), [-1, 0, -1, 0, -1, 0])
}

///|
test "integer extension compiled calls and bounds" {
  let m = @forth.Machine::new()
  m.eval(": scale 100000 100000 */ ; 100000 scale")
  assert_eq(m.values(), [100000])
  for
    source in [
      "*/", "1 /mod", "1 2 0 */", "-2147483648 -1 /mod", "2147483647 2 1 */", "1 32 lshift",
      "1 -1 rshift",
    ] {
    let n = @forth.Machine::new()
    assert_true(
      try {
        n.eval(source)
        false
      } catch {
        _ => true
      },
    )
  }
}
