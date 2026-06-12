----- SOURCE CODE -- main.bp
```botopink
fn calc(factor: i32) -> i32 {
    @todo();
}
fn main() {
    val r = calc(2) { a, b ->
        return 0;
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $calc (param $factor i32) (result i32)
    unreachable
  )
  (func $main
    (local $r i32)
    i32.const 2
    call $calc
    local.set $r
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
)
```

----- RUN LOG -----
```logs
```
