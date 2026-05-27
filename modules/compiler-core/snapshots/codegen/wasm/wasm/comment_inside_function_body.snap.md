----- SOURCE CODE -- main.bp
```botopink
fn main() {
    // Initialize value
    val x = 1;
    // Return null
    null;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $main
    (local $x i32)
    drop
    i32.const 1
    local.set $x
    drop
    i32.const 0
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
)
```

----- RUN LOG -----
```logs
```
