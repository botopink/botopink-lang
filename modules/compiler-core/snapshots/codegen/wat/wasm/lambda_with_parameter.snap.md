----- SOURCE CODE -- main.bp
```botopink
fn apply(f: syntax fn(x: i32) -> i32) -> i32 {
    return f(10);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (table funcref (elem))
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $apply (param $f i32) (result i32)
    (local $__fnv0 i32)
    local.get $f
    local.set $__fnv0
    local.get $__fnv0
    i32.const 10
    local.get $__fnv0
    i32.load ;; table index
    call_indirect (param i32 i32) (result i32)
    return
  )
)
```

----- RUN LOG -----
```logs
```
