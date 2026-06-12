----- SOURCE CODE -- main.bp
```botopink
record ParseError { msg: string }
val Parser = struct {
    fn parse(self: Self) -> @Result<i32, ParseError> {
        throw ParseError(msg: "bad input");
    }
}
fn run(p: Parser) -> i32 {
    val result = p.parse() catch 0;
    return result;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\09\00\00\00bad input")
  (global $__heap_ptr (mut i32) (i32.const 272))
  (func $Parser_parse (param $self i32)
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 256
    i32.store
    local.get $__mem0
    unreachable
  )
  (func $run (param $p i32) (result i32)
    (local $_try0 i32)
    (local $result i32)
    call $parse
    local.set $_try0
    local.get $_try0
    i32.load ;; Result tag (0 = Ok, non-zero = Error)
    (if (result i32)
      (then
    i32.const 0
      )
      (else
    local.get $_try0
    i32.load offset=4 ;; Ok payload
      )
    )
    local.set $result
    local.get $result
    return
  )
)
```

----- RUN LOG -----
```logs
```
