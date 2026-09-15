----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
fn first(p: Point) -> i32 {
    return p.x;
}
fn second(p: Point) -> i32 {
    return p.y;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $first (param $p i32) (result i32)
    local.get $p
    i32.load ;; .x
    return
  )
  (func $second (param $p i32) (result i32)
    local.get $p
    i32.load offset=4 ;; .y
    return
  )
)
```

----- RUN LOG -----
```logs
```
