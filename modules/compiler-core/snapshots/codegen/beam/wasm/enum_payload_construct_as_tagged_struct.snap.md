----- SOURCE CODE -- main.bp
```botopink
type Shape {
    Circle(r: i32),
    Square(side: i32),
}
fn makeCircle() -> Shape {
    return Shape.Circle(r: 5);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\12\00\00\00V\0cShape.Circle\01\01ri")
  (global $__heap_ptr (mut i32) (i32.const 280))
  (func $makeCircle (result i32)
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    i32.const 5
    i32.store offset=8
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
)
```

----- RUN LOG -----
```logs
```
