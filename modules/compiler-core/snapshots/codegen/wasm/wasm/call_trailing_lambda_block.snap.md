----- SOURCE CODE -- main.bp
```botopink
fn run() {
    @todo();
}
fn main() {
    run { x ->
        return "done";
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $run
    unreachable
  )
  (func $main
    call $run
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
)
```

----- RUN LOG -----
```logs
```
