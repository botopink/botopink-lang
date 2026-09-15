----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32, z: i32 }
fn describe(p: Point) -> i32 {
    val { x, .. } = p;
    return x;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $describe (param $p i32) (result i32)
    (local $__mem0 i32)
    (local $x i32)
    local.get $p
    local.set $__mem0
    local.get $__mem0
    i32.load
    local.set $x
    local.get $x
    return
  )
)
```

----- RUN LOG -----
```logs
```
