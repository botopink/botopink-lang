----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val answer = 42;
    val assert 42 = answer catch throw "not 42";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\06\00\00\00not 42")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $f (result i32)
    (local $answer i32)
    (local $__assert_0 i32)
    i32.const 42
    local.set $answer
    local.get $answer
    local.set $__assert_0
    local.get $__assert_0
    i32.const 42
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 256
    drop
    unreachable
      )
    )
    i32.const 0
  )
)
```

----- RUN LOG -----
```logs
```
