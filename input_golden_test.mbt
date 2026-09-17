// Generated from reference fields only by tools/generate-input-golden.py.

///|
test "Gforth input oracle 128 portable programs" {
  {
    let m = @forth.Machine::new()
    // arithmetic
    m.eval("7 3 + 2 * 5 -", budget=1000000)
    assert_eq(m.values(), [15])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // stack
    m.eval("1 2 3 rot 2dup +", budget=1000000)
    assert_eq(m.values(), [2, 3, 1, 4])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // binding
    m.eval(": a 3 ; : b a ; : a 9 ; b a", budget=1000000)
    assert_eq(m.values(), [3, 9])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // same name
    m.eval(": a 1 ; : a a 1+ ; a", budget=1000000)
    assert_eq(m.values(), [2])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // primitive binding
    m.eval(": saved dup ; : dup 99 ; 2 saved dup", budget=1000000)
    assert_eq(m.values(), [2, 2, 99])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // begin
    m.eval(": count 0 begin 1+ dup 4 = until ; count", budget=1000000)
    assert_eq(m.values(), [4])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // while
    m.eval(": count 3 begin dup 0> while 1- repeat ; count", budget=1000000)
    assert_eq(m.values(), [0])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // do
    m.eval(": indices 3 0 do i loop ; indices", budget=1000000)
    assert_eq(m.values(), [0, 1, 2])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // nested do
    m.eval(": indices 2 0 do 2 0 do j i loop loop ; indices", budget=1000000)
    assert_eq(m.values(), [0, 0, 0, 1, 1, 0, 1, 1])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // plusloop
    m.eval(": indices 5 0 do i 2 +loop ; indices", budget=1000000)
    assert_eq(m.values(), [0, 2, 4])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // negative loop
    m.eval(": indices 0 3 do i -1 +loop ; indices", budget=1000000)
    assert_eq(m.values(), [3, 2, 1, 0])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // leave
    m.eval(
      ": indices 9 0 do i dup 2 = if leave then loop ; indices",
      budget=1000000,
    )
    assert_eq(m.values(), [0, 1, 2])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // return stack
    m.eval(": f 3 >r 8 r@ r> ; f", budget=1000000)
    assert_eq(m.values(), [8, 3, 3])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // pair return
    m.eval(": f 3 4 2>r 2r@ 2r> ; f", budget=1000000)
    assert_eq(m.values(), [3, 4, 3, 4])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // exit
    m.eval(": f dup 0= if drop 7 exit then 1+ ; 0 f 4 f", budget=1000000)
    assert_eq(m.values(), [7, 5])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // unloop
    m.eval(": f 5 0 do i dup 2 = if unloop exit then loop ; f", budget=1000000)
    assert_eq(m.values(), [0, 1, 2])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // recurse
    m.eval(
      ": f dup 2 < if drop 1 exit then dup 1- recurse * ; 5 f",
      budget=1000000,
    )
    assert_eq(m.values(), [120])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // xt
    m.eval(": f 4 ; ' f constant old : f 8 ; old execute f", budget=1000000)
    assert_eq(m.values(), [4, 8])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // anonymous
    m.eval(":noname dup * ; constant square 7 square execute", budget=1000000)
    assert_eq(m.values(), [49])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // does
    m.eval(": con create , does> @ ; 7 con a 9 con b a b", budget=1000000)
    assert_eq(m.values(), [7, 9])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // body
    m.eval(": con create , does> @ ; 4 con a 7 ' a >body ! a", budget=1000000)
    assert_eq(m.values(), [7])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // literal
    m.eval(": value [ 7 7 * 2 + ] literal ; value", budget=1000000)
    assert_eq(m.values(), [51])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // immediate
    m.eval(
      ": seven 7 ; immediate : value seven literal ; value",
      budget=1000000,
    )
    assert_eq(m.values(), [7])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // compile comma
    m.eval(
      ": emitdup ['] dup compile, ; immediate : double emitdup + ; 6 double",
      budget=1000000,
    )
    assert_eq(m.values(), [12])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // postpone
    m.eval(
      ": endif postpone then ; immediate : choice if 7 else 8 endif ; 1 choice 0 choice",
      budget=1000000,
    )
    assert_eq(m.values(), [7, 8])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // state
    m.eval(
      ": mode state @ ; immediate : compiled mode literal ; : interpreted [ mode ] literal ; compiled interpreted mode",
      budget=1000000,
    )
    assert_eq(m.values(), [-1, 0, 0])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // literal string
    m.eval("s\" Hello 世界\" type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(
      m.output_bytes(),
      b"\x48\x65\x6c\x6c\x6f\x20\xe4\xb8\x96\xe7\x95\x8c",
    )
  }
  {
    let m = @forth.Machine::new()
    // compiled print
    m.eval(": hi .\" Mixed CASE\" cr ; hi hi", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(
      m.output_bytes(),
      b"\x4d\x69\x78\x65\x64\x20\x43\x41\x53\x45\x0a\x4d\x69\x78\x65\x64\x20\x43\x41\x53\x45\x0a",
    )
  }
  {
    let m = @forth.Machine::new()
    // counted string
    m.eval(": data c\" Case\" ; data count type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x43\x61\x73\x65")
  }
  {
    let m = @forth.Machine::new()
    // empty strings
    m.eval("s\" \" dup . type s\" \" s\" \" compare", budget=1000000)
    assert_eq(m.values(), [0])
    assert_eq(m.output_bytes(), b"\x30\x20")
  }
  {
    let m = @forth.Machine::new()
    // char literal
    m.eval("char Z 'A' : x [char] Q ; x", budget=1000000)
    assert_eq(m.values(), [90, 65, 81])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // parse name
    m.eval(": read parse-name type ; read MiXeD read 世界", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x4d\x69\x58\x65\x44\xe4\xb8\x96\xe7\x95\x8c")
  }
  {
    let m = @forth.Machine::new()
    // parse delimiter
    m.eval("124 parse abc  def| type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x61\x62\x63\x20\x20\x64\x65\x66")
  }
  {
    let m = @forth.Machine::new()
    // parse end
    m.eval(": rest 124 parse type ; rest xyz", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x78\x79\x7a")
  }
  {
    let m = @forth.Machine::new()
    // parse empty
    m.eval("124 parse | dup . type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x30\x20")
  }
  {
    let m = @forth.Machine::new()
    // input cursor
    m.eval(": peek source drop >in @ + c@ ; peek 7", budget=1000000)
    assert_eq(m.values(), [55, 7])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // skip input
    m.eval("source nip >in ! bad-ignored", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // source length
    m.eval("source nip", budget=1000000)
    assert_eq(m.values(), [10])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // source id
    m.eval("source-id", budget=1000000)
    assert_eq(m.values(), [-1])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // evaluate
    m.eval("s\" 3 4 +\" evaluate 9", budget=1000000)
    assert_eq(m.values(), [7, 9])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // nested eval
    m.eval(
      ": input s\" 7 9 +\" ; : second s\" input evaluate\" ; second evaluate",
      budget=1000000,
    )
    assert_eq(m.values(), [16])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // evaluate define
    m.eval("s\" : x 7 ; x\" evaluate x", budget=1000000)
    assert_eq(m.values(), [7, 7])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // parse immediate
    m.eval(
      ": size parse-name nip postpone literal ; immediate : x size MiXeD ; x",
      budget=1000000,
    )
    assert_eq(m.values(), [5])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // unbalanced compile data stack rejected
    let code = try {
      m.eval(
        ": text s\" 4 5 +\" ; immediate : x text evaluate ; x",
        budget=1000000,
      )
      0
    } catch {
      error => error.code()
    }
    assert_eq(code, -2)
  }
  {
    let m = @forth.Machine::new()
    // base compile
    m.eval("hex : x 10 ff ; decimal x", budget=1000000)
    assert_eq(m.values(), [16, 255])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // explicit prefixes
    m.eval("$FF %1010 #12", budget=1000000)
    assert_eq(m.values(), [255, 10, 12])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // base setter
    m.eval("16 base ! ab decimal", budget=1000000)
    assert_eq(m.values(), [171])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // number output
    m.eval("hex 123 . 255 u. decimal -7 4 .r 255 4 u.r", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(
      m.output_bytes(),
      b"\x31\x32\x33\x20\x32\x35\x35\x20\x20\x20\x2d\x37\x20\x32\x35\x35",
    )
  }
  {
    let m = @forth.Machine::new()
    // trim
    m.eval("s\" abc   \" -trailing type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x61\x62\x63")
  }
  {
    let m = @forth.Machine::new()
    // slice
    m.eval("s\" abcdef\" 3 /string type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x64\x65\x66")
  }
  {
    let m = @forth.Machine::new()
    // compare
    m.eval(
      "s\" abc\" s\" abd\" compare s\" x\" s\" x\" compare",
      budget=1000000,
    )
    assert_eq(m.values(), [-1, 0])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // search
    m.eval("s\" abcdef\" s\" cd\" search . type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x2d\x31\x20\x63\x64\x65\x66")
  }
  {
    let m = @forth.Machine::new()
    // not found
    m.eval("s\" abc\" s\" z\" search . type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x30\x20\x61\x62\x63")
  }
  {
    let m = @forth.Machine::new()
    // word
    m.eval(": item 32 word count type ; item Hello item World", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x48\x65\x6c\x6c\x6f\x57\x6f\x72\x6c\x64")
  }
  {
    let m = @forth.Machine::new()
    // two cell
    m.eval("create x 2 cells allot 12 34 x 2! x 2@", budget=1000000)
    assert_eq(m.values(), [12, 34])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // extra stack
    m.eval("1 2 3 4 2over 1 pick 2 roll", budget=1000000)
    assert_eq(m.values(), [1, 2, 3, 4, 2, 1, 1])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // catch success
    m.eval(": x 7 ; 1 ' x catch", budget=1000000)
    assert_eq(m.values(), [1, 7, 0])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // catch throw
    m.eval(": x 9 -77 throw ; 5 ' x catch", budget=1000000)
    assert_eq(m.values(), [5, -77])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // nested catch
    m.eval(
      ": x -77 throw ; : y ['] x catch -88 throw ; 4 ' y catch",
      budget=1000000,
    )
    assert_eq(m.values(), [4, -88])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // throw zero
    m.eval("1 0 throw 2", budget=1000000)
    assert_eq(m.values(), [1, 2])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // catch divide
    m.eval(": x 1 0 / ; ' x catch", budget=1000000)
    assert_eq(m.values(), [-10])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // catch unknown
    m.eval(": x s\" missing\" evaluate ; ' x catch", budget=1000000)
    assert_eq(m.values(), [-13])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // catch return
    m.eval(": x 3 >r -88 throw r> ; 4 ' x catch 5", budget=1000000)
    assert_eq(m.values(), [4, -88, 5])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // catch loop
    m.eval(
      ": x 9 0 do i 3 = if -99 throw then loop ; 4 ' x catch",
      budget=1000000,
    )
    assert_eq(m.values(), [4, -99])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // catch eval
    m.eval(": x s\" -12 throw\" evaluate ; ' x catch 6", budget=1000000)
    assert_eq(m.values(), [-12, 6])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // undefined
    let code = try {
      m.eval("missing", budget=1000000)
      0
    } catch {
      error => error.code()
    }
    assert_eq(code, -13)
  }
  {
    let m = @forth.Machine::new()
    // division
    let code = try {
      m.eval("1 0 /", budget=1000000)
      0
    } catch {
      error => error.code()
    }
    assert_eq(code, -10)
  }
  {
    let m = @forth.Machine::new()
    // underflow
    let code = try {
      m.eval("drop", budget=1000000)
      0
    } catch {
      error => error.code()
    }
    assert_eq(code, -4)
  }
  {
    let m = @forth.Machine::new()
    // string length 0
    m.eval("s\" \" dup . type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x30\x20")
  }
  {
    let m = @forth.Machine::new()
    // string length 1
    m.eval("s\" Z\" dup . type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x31\x20\x5a")
  }
  {
    let m = @forth.Machine::new()
    // string length 2
    m.eval("s\" Ab\" dup . type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x32\x20\x41\x62")
  }
  {
    let m = @forth.Machine::new()
    // string length 7
    m.eval("s\" AbAbAbZ\" dup . type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x37\x20\x41\x62\x41\x62\x41\x62\x5a")
  }
  {
    let m = @forth.Machine::new()
    // string length 31
    m.eval("s\" AbAbAbAbAbAbAbAbAbAbAbAbAbAbAbZ\" dup . type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(
      m.output_bytes(),
      b"\x33\x31\x20\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x5a",
    )
  }
  {
    let m = @forth.Machine::new()
    // string length 127
    m.eval(
      "s\" AbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbZ\" dup . type",
      budget=1000000,
    )
    assert_eq(m.values(), [])
    assert_eq(
      m.output_bytes(),
      b"\x31\x32\x37\x20\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x5a",
    )
  }
  {
    let m = @forth.Machine::new()
    // string length 255
    m.eval(
      "s\" AbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbAbZ\" dup . type",
      budget=1000000,
    )
    assert_eq(m.values(), [])
    assert_eq(
      m.output_bytes(),
      b"\x32\x35\x35\x20\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x41\x62\x5a",
    )
  }
  {
    let m = @forth.Machine::new()
    // radix format 2/0
    m.eval("0 2 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [0])
    assert_eq(m.output_bytes(), b"\x30\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 2/1
    m.eval("1 2 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [1])
    assert_eq(m.output_bytes(), b"\x31\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 2/15
    m.eval("15 2 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [15])
    assert_eq(m.output_bytes(), b"\x31\x31\x31\x31\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 2/255
    m.eval("255 2 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [255])
    assert_eq(m.output_bytes(), b"\x31\x31\x31\x31\x31\x31\x31\x31\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 2/12345
    m.eval("12345 2 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [12345])
    assert_eq(
      m.output_bytes(),
      b"\x31\x31\x30\x30\x30\x30\x30\x30\x31\x31\x31\x30\x30\x31\x20",
    )
  }
  {
    let m = @forth.Machine::new()
    // radix format 3/0
    m.eval("0 3 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [0])
    assert_eq(m.output_bytes(), b"\x30\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 3/1
    m.eval("1 3 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [1])
    assert_eq(m.output_bytes(), b"\x31\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 3/15
    m.eval("15 3 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [15])
    assert_eq(m.output_bytes(), b"\x31\x32\x30\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 3/255
    m.eval("255 3 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [255])
    assert_eq(m.output_bytes(), b"\x31\x30\x30\x31\x31\x30\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 3/12345
    m.eval("12345 3 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [12345])
    assert_eq(m.output_bytes(), b"\x31\x32\x31\x32\x32\x31\x30\x32\x30\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 8/0
    m.eval("0 8 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [0])
    assert_eq(m.output_bytes(), b"\x30\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 8/1
    m.eval("1 8 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [1])
    assert_eq(m.output_bytes(), b"\x31\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 8/15
    m.eval("15 8 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [15])
    assert_eq(m.output_bytes(), b"\x31\x37\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 8/255
    m.eval("255 8 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [255])
    assert_eq(m.output_bytes(), b"\x33\x37\x37\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 8/12345
    m.eval("12345 8 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [12345])
    assert_eq(m.output_bytes(), b"\x33\x30\x30\x37\x31\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 10/0
    m.eval("0 10 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [0])
    assert_eq(m.output_bytes(), b"\x30\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 10/1
    m.eval("1 10 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [1])
    assert_eq(m.output_bytes(), b"\x31\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 10/15
    m.eval("15 10 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [15])
    assert_eq(m.output_bytes(), b"\x31\x35\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 10/255
    m.eval("255 10 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [255])
    assert_eq(m.output_bytes(), b"\x32\x35\x35\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 10/12345
    m.eval("12345 10 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [12345])
    assert_eq(m.output_bytes(), b"\x31\x32\x33\x34\x35\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 16/0
    m.eval("0 16 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [0])
    assert_eq(m.output_bytes(), b"\x30\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 16/1
    m.eval("1 16 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [1])
    assert_eq(m.output_bytes(), b"\x31\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 16/15
    m.eval("15 16 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [15])
    assert_eq(m.output_bytes(), b"\x46\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 16/255
    m.eval("255 16 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [255])
    assert_eq(m.output_bytes(), b"\x46\x46\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 16/12345
    m.eval("12345 16 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [12345])
    assert_eq(m.output_bytes(), b"\x33\x30\x33\x39\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 24/0
    m.eval("0 24 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [0])
    assert_eq(m.output_bytes(), b"\x30\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 24/1
    m.eval("1 24 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [1])
    assert_eq(m.output_bytes(), b"\x31\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 24/15
    m.eval("15 24 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [15])
    assert_eq(m.output_bytes(), b"\x46\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 24/255
    m.eval("255 24 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [255])
    assert_eq(m.output_bytes(), b"\x41\x46\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 24/12345
    m.eval("12345 24 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [12345])
    assert_eq(m.output_bytes(), b"\x4c\x41\x39\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 36/0
    m.eval("0 36 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [0])
    assert_eq(m.output_bytes(), b"\x30\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 36/1
    m.eval("1 36 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [1])
    assert_eq(m.output_bytes(), b"\x31\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 36/15
    m.eval("15 36 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [15])
    assert_eq(m.output_bytes(), b"\x46\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 36/255
    m.eval("255 36 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [255])
    assert_eq(m.output_bytes(), b"\x37\x33\x20")
  }
  {
    let m = @forth.Machine::new()
    // radix format 36/12345
    m.eval("12345 36 base ! dup . decimal", budget=1000000)
    assert_eq(m.values(), [12345])
    assert_eq(m.output_bytes(), b"\x39\x49\x58\x20")
  }
  {
    let m = @forth.Machine::new()
    // throw -1
    m.eval(": fail -1 throw ; 10 20 ' fail catch", budget=1000000)
    assert_eq(m.values(), [10, 20, -1])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // throw -2
    m.eval(": fail -2 throw ; 10 20 ' fail catch", budget=1000000)
    assert_eq(m.values(), [10, 20, -2])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // throw -77
    m.eval(": fail -77 throw ; 10 20 ' fail catch", budget=1000000)
    assert_eq(m.values(), [10, 20, -77])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // throw 1
    m.eval(": fail 1 throw ; 10 20 ' fail catch", budget=1000000)
    assert_eq(m.values(), [10, 20, 1])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // throw 99
    m.eval(": fail 99 throw ; 10 20 ' fail catch", budget=1000000)
    assert_eq(m.values(), [10, 20, 99])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // evaluate during compilation
    m.eval(
      ": text s\" 4 5 +\" evaluate ; immediate : x text ; x",
      budget=1000000,
    )
    assert_eq(m.values(), [9])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // escaped bytes
    m.eval(
      ": bytes s\\\" A\\nB\\xFF\\z\\q\\m\\t\\v\\\\\" ; bytes type",
      budget=1000000,
    )
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x41\x0a\x42\xff\x00\x22\x0d\x0a\x09\x0b\x5c")
  }
  {
    let m = @forth.Machine::new()
    // saved input
    m.eval(
      ": twice save-input parse-name type restore-input drop parse-name type ; twice AbC refill",
      budget=1000000,
    )
    assert_eq(m.values(), [0])
    assert_eq(m.output_bytes(), b"\x41\x62\x43\x41\x62\x43")
  }
  {
    let m = @forth.Machine::new()
    // abort quote
    m.eval(
      ": checked abort\" Bad value\" 9 ; 0 checked 1 ' checked catch swap drop",
      budget=1000000,
    )
    assert_eq(m.values(), [9, -2])
    assert_eq(m.output_bytes(), b"")
  }
  {
    let m = @forth.Machine::new()
    // postponed quote
    m.eval(
      ": message postpone .\" ; immediate : x message Hello CASE\" ; x",
      budget=1000000,
    )
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x48\x65\x6c\x6c\x6f\x20\x43\x41\x53\x45")
  }
  {
    let m = @forth.Machine::new()
    // parenthesis output
    m.eval(".( Case Here) 7", budget=1000000)
    assert_eq(m.values(), [7])
    assert_eq(m.output_bytes(), b"\x43\x61\x73\x65\x20\x48\x65\x72\x65")
  }
  {
    let m = @forth.Machine::new()
    // blank buffer
    m.eval("create b 8 allot b 8 65 fill b 4 blank b 8 type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x20\x20\x20\x20\x41\x41\x41\x41")
  }
  {
    let m = @forth.Machine::new()
    // byte copy
    m.eval(
      "create b 8 allot s\" AbCdEfGh\" b swap move b 8 type",
      budget=1000000,
    )
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x41\x62\x43\x64\x45\x66\x47\x68")
  }
  {
    let m = @forth.Machine::new()
    // number output letters
    m.eval("hex abcd . ff u. decimal", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x41\x42\x43\x44\x20\x46\x46\x20")
  }
  {
    let m = @forth.Machine::new()
    // search repeated prefix
    m.eval("s\" aaaaab\" s\" aaab\" search . type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x2d\x31\x20\x61\x61\x61\x62")
  }
  {
    let m = @forth.Machine::new()
    // search empty needle
    m.eval("s\" abc\" s\" \" search . type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(m.output_bytes(), b"\x2d\x31\x20\x61\x62\x63")
  }
  {
    let m = @forth.Machine::new()
    // comment in string
    m.eval("s\" ( This \\ is not a comment )\" type", budget=1000000)
    assert_eq(m.values(), [])
    assert_eq(
      m.output_bytes(),
      b"\x28\x20\x54\x68\x69\x73\x20\x5c\x20\x69\x73\x20\x6e\x6f\x74\x20\x61\x20\x63\x6f\x6d\x6d\x65\x6e\x74\x20\x29",
    )
  }
  let m = @forth.Machine::new()
  // empty parse name
  m.eval(": end parse-name nip ; end", budget=1000000)
  assert_eq(m.values(), [0])
  assert_eq(m.output_bytes(), b"")
}
