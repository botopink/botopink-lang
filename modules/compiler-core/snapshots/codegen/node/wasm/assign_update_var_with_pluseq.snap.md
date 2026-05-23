----- SOURCE CODE -- main.bp
```botopink
fn increment() {
    var count = 0;
    count += 1;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $increment
    (local $count i32)
    i32.const 0
    local.set $count
    local.get $count
    i32.const 1
    i32.add
    local.set $count
  )
)
```

----- RUN LOG -----
```logs
```
