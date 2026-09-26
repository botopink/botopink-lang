----- SOURCE CODE -- main.bp
```botopink
/// This function greets the user
fn greet(name: string) -> string {
    return name;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; This function greets the user
  (func $greet (param $name i32) (result i32)
    local.get $name
    return
  )
)
```

----- RUN LOG -----
```logs
```
