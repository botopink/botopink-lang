----- SOURCE CODE -- main.bp
```botopink
fn n() -> i32 {
    val s = "hello";
    return s.len;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\05\00\00\00hello")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $n (result i32)
    (local $s i32)
    i32.const 256
    local.set $s
    local.get $s
    i32.load ;; string length
    return
  )
)
```

----- RUN LOG -----
```logs
```
