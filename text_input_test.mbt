///|
test "text source preserves UTF8 case spaces and compiled literals" {
  let m = @forth.Machine::new()
  m.eval(
    ": say .\" Hello 世界\" cr ; say 65 emit space s\" Keep CASE (x)\" type",
  )
  assert_eq(m.output_text(), "Hello 世界\nA Keep CASE (x)")
  m.clear_output()
  m.eval(
    ": greeting s\" Mixed Case\" ; greeting type greeting type : letter [char] Z ; char A letter 'Q'",
  )
  assert_eq(m.output_text(), "Mixed CaseMixed Case")
  assert_eq(m.values(), [65, 90, 81])
}

///|
test "raw source parse names delimiters cursor and nested evaluate" {
  let m = @forth.Machine::new()
  m.eval(": name parse-name ; name AbC type 124 parse xyz| type")
  assert_eq(m.output_text(), "AbCxyz")
  m.eval(": peek source drop >in @ + c@ ; peek 7")
  assert_eq(m.values(), [55, 7])
  m.eval("source nip >in ! ignored-invalid-text")
  m.eval("s\" 3 4 +\" evaluate s\" : nested 11 ; nested\" evaluate 9")
  assert_eq(m.values(), [55, 7, 7, 11, 9])
}

///|
test "radix parsing output compile binding and explicit prefixes" {
  let m = @forth.Machine::new()
  m.eval(
    "hex : hex-value 10 ff ; decimal hex-value $FFFFFFFF %101 #-42 16 base ! a decimal",
  )
  assert_eq(m.values(), [16, 255, -1, 5, -42, 10])
  m.eval("hex 255 u. decimal -7 4 .r 255 4 u.r")
  assert_eq(m.output_text(), "255   -7 255")
  assert_true(
    try {
      m.eval("1 base !")
      false
    } catch {
      _ => true
    },
  )
  m.eval("10")
  assert_eq(m.values().last(), Some(10))
}

///|
test "input parsing immediate macro and evaluate while compiling" {
  let m = @forth.Machine::new()
  m.eval(
    ": size parse-name nip postpone literal ; immediate : size-value size AbCdEf ; size-value",
  )
  assert_eq(m.values(), [6])
  m.eval(": text s\" 4 5 +\" evaluate ; immediate : result text ; result")
  assert_eq(m.values(), [6, 9])
}

///|
test "catch throw restores data return loops and source frame" {
  let m = @forth.Machine::new()
  m.eval(": bad 9 >r 5 0 do i 2 = if -77 throw then loop r> ; 123 ' bad catch")
  assert_eq(m.values(), [123, -77])
  m.eval(": good 4 ; ' good catch : noop 0 throw 8 ; ' noop catch")
  assert_eq(m.values(), [123, -77, 4, 0, 8, 0])
  m.eval(": inner s\" -88 throw\" evaluate ; ' inner catch 19")
  assert_eq(m.values().last(), Some(19))
  let n = @forth.Machine::new()
  n.eval(": missing s\" unknown\" evaluate ; ' missing catch ' drop catch")
  assert_eq(n.values(), [0])
}

///|
test "counted strings memory operations and string comparisons" {
  let m = @forth.Machine::new()
  m.eval(
    ": counted c\" Hello\" ; counted count type s\" abc  \" -trailing type s\" ABC\" 1 /string type",
  )
  assert_eq(m.output_text(), "HelloabcBC")
  m.eval("s\" abc\" s\" abd\" compare s\" AbC\" s\" b\" search drop type")
  assert_eq(m.values(), [-1])
  assert_eq(m.output_text(), "HelloabcBCbC")
  m.eval(
    "create pair 8 allot 12 34 pair 2! pair 2@ 1 2 3 4 2over 1 pick 2 roll",
  )
  assert_eq(m.values(), [-1, 12, 34, 1, 2, 3, 4, 2, 1, 1])
}

///|
test "source failures release frames and strings respect limits" {
  let m = @forth.Machine::new()
  for
    code in [
      "s\" unfinished", "-1 >in !", "source nip 1+ >in !", "s\" 1 0 /\" evaluate",
      ": failed [ 3 ;",
    ] {
    assert_true(
      try {
        m.eval(code)
        false
      } catch {
        _ => true
      },
    )
    m.eval("source-id drop")
  }
  assert_true(
    try {
      m.eval(": recursive s\" recursive\" evaluate ; recursive", budget=1000)
      false
    } catch {
      _ => true
    },
  )
  m.eval("6 7 +")
  assert_eq(m.values(), [13])
}

///|
test "persistent feed compiles across buffers and errors recover" {
  let m = @forth.Machine::new()
  assert_true(m.feed(": square"))
  assert_true(m.is_compiling())
  assert_true(m.feed("dup"))
  assert_true(!m.feed("* ; 9 square"))
  assert_eq(m.values(), [81])
  assert_true(m.feed(": value ["))
  assert_true(m.feed("6 7 +"))
  assert_true(!m.feed("] literal ; value"))
  assert_eq(m.values(), [81, 13])
  assert_true(m.feed(": broken"))
  assert_true(
    try {
      ignore(m.feed("missing ;"))
      false
    } catch {
      _ => true
    },
  )
  assert_true(!m.is_compiling())
  m.eval("square")
  assert_eq(m.values(), [81, 169])
}

///|
test "escaped strings preserve raw bytes and abort quote is catchable" {
  let m = @forth.Machine::new()
  m.eval(": bytes s\\\" A\\nB\\xFF\\z\\q\\m\\t\\v\\\\\" ; bytes type")
  assert_eq(m.output_bytes(), b"A\x0aB\xff\x00\"\x0d\x0a\x09\x0b\\")
  m.clear_output()
  m.eval(": checked abort\" Bad value\" 9 ; 0 checked 1 ' checked catch")
  assert_eq(m.values(), [9, 1, -2])
  assert_eq(m.output_text(), "")
  assert_true(
    try {
      m.eval("s\\\" \\xQ0\"")
      false
    } catch {
      _ => true
    },
  )
}

///|
test "saved input replay and linear string search" {
  let m = @forth.Machine::new()
  m.eval(
    ": twice save-input parse-name type restore-input drop parse-name type ; twice AbC refill",
  )
  assert_eq(m.output_text(), "AbCAbC")
  assert_eq(m.values(), [0])
  let haystack = Array::make(20000, "a").join("") + "b"
  let needle = Array::make(10000, "a").join("") + "b"
  m.eval(
    "s\" " + haystack + "\" s\" " + needle + "\" search nip nip",
    budget=100000,
  )
  assert_eq(m.values(), [0, -1])
  assert_true(
    try {
      m.eval("s\" abc\" drop 0 swap c!")
      false
    } catch {
      _ => true
    },
  )
}
