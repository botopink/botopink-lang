----- SOURCE CODE -- main.bp
```botopink
fn describe() -> string {
    val items = ["a", "b", "c"];
    return case items {
        [] -> "empty";
        [x] -> "one";
        [first, ..rest] -> "many";
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "empty")
  (global $__heap_ptr (mut i32) (i32.const 264))
  (func $describe (result i32)
    (local $items i32)
    i32.const 0 ;; array
    local.set $items
    local.get $items
    (local $__case_0 i32)
    local.set $__case_0
    i32.const 256
    return
  )
)
```

----- RUN LOG -----
```logs
```
