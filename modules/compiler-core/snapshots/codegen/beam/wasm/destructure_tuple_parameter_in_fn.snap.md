----- SOURCE CODE -- main.bp
```botopink
fn process(#(x, y): #(i32, i32)) -> i32 {
    return x;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $process (param $__p0 i32) (result i32)
    (local $x i32)
    (local $y i32)
    local.get $__p0
    i32.load
    local.set $x
    local.get $__p0
    i32.load offset=4
    local.set $y
    local.get $x
    return
  )
)
```

----- RUN LOG -----
```logs
```
