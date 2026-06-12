----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val func: fn(string)-> string = {s ->
        return s;
    };
    return func("hello");
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\05\00\00\00hello")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $main (result i32)
    (local $func i32)
    i32.const 0 ;; lambda
    local.set $func
    i32.const 256
    call $func
    return
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
    drop
  )
)
```

----- RUN LOG -----
```logs
```
