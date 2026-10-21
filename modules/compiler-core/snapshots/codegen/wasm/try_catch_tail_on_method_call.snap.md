----- SOURCE CODE -- main.bp
```botopink
type ParseError(msg: string)
val Parser = type() {
    fn parse(self: Self) -> Result<i32, ParseError> {
        throw ParseError(msg: "bad input");
    }
}
fn run(p: Parser) -> i32 {
    val result = try p.parse() catch 0;
    return result;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $rec_ParseError (struct (field $f0 (mut (ref null $str)))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $rec_Parser (struct))
    (type $box_i32 (struct (field $v i32)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $Parser_parse (param $self (ref null $rec_Parser)) (result (ref null $result))
    (local $__mem0 i32)
    i32.const 1
    global.get $__s0
    struct.new $rec_ParseError
    struct.new $result
    return
  )
  (func $run (param $p (ref null $rec_Parser)) (result i32)
    (local $_try0 i32)
    (local $result i32)
    (local $__gc0 (ref null $result))
    local.get $p
    call $Parser_parse
    local.set $__gc0
    local.get $__gc0
    struct.get $result $tag ;; Result tag (0 = Ok, non-zero = Error)
    (if (result i32)
      (then
    i32.const 0
      )
      (else
    local.get $__gc0
    struct.get $result $payload ;; Ok payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
      )
    )
    local.set $result
    local.get $result
    return
  )
  (data $__d0 "bad input")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 9
    array.new_data $str $__d0
    global.set $__s0
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
