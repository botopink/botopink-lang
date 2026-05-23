----- SOURCE CODE -- main.bp
```botopink
fn double(x: i32) -> i32 { return x * 2; }
fn inc(x: i32) -> i32 { return x + 1; }
fn main() {
    val result = 1
        |> double
        |> inc;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $double (param $x i32) (result i32)
    local.get $x
    i32.const 2
    i32.mul
    return
  )
  (func $inc (param $x i32) (result i32)
    local.get $x
    i32.const 1
    i32.add
    return
  )
  (func $main
    (local $result i32)
    i32.const 1
    call $double
    call $inc
    local.set $result
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
)
```

----- RUN LOG -----
```logs
```
