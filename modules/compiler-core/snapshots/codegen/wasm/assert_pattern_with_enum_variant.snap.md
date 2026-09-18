----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn parse() -> @Result<i32, string> {
    return 42;
}
fn f() {
    val result = parse();
    val assert Ok(value) = result catch throw "not ok";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $parse (result i32)
    (local $_res0 i32)
    global.get $__heap_ptr
    local.set $_res0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $_res0
    i32.const 0
    i32.store ;; Result tag (Ok)
    local.get $_res0
    i32.const 42
    i32.store offset=4 ;; payload
    local.get $_res0
    return
  )
  (func $f (result i32)
    (local $result i32)
    call $parse
    local.set $result
    i32.const 0
  )
)
```

----- RUN LOG -----
```logs
```
