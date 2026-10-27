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
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (data (i32.const 11696) "\05\00\00\00hello")
  (func $n (result i32)
    (local $s i32)
    i32.const 11696
    local.set $s
    local.get $s
    i32.load ;; string length
    return
  )
  (start $__bp_reserve)
  (func $__bp_reserve
    global.get $__heap_ptr
    i32.const 11708
    i32.lt_u
    (if
      (then
      i32.const 11708
      global.set $__heap_ptr
      )
    )
  )
)
```

----- RUN LOG -----
```logs
```
