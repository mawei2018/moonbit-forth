# 可执行 API 示例

增加 nip/tuck/2dup/2drop/2swap 标准栈操作及下溢检查。这些例子调用公开 API，并随 `moon test` 执行。

```mbt check
///|
test "extended standard stack words" {
  let m = @forth.Machine::new()
  m.eval("1 2 2dup 2swap 2drop nip")
  assert_eq(m.values(), [2])
  let t = @forth.Machine::new()
  t.eval("1 2 tuck")
  assert_eq(t.values(), [2, 1, 2])
  assert_true(
    try {
      let x = @forth.Machine::new()
      x.eval("2dup")
      false
    } catch {
      _ => true
    },
  )
}
```

限制：不是完整 ANS Forth；词汇、内存模型和控制流仍为子集。
