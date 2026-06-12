----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
fn recordEq() -> bool {
    val a = Point(x: 1, y: 2);
    val b = Point(x: 1, y: 2);
    return a == b;
}
fn arrayEq() -> bool {
    val xs = [1, 2];
    val ys = [1, 2];
    return xs == ys;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $recordEq (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $a i32)
    (local $b i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 1
    i32.store
    local.get $__mem0
    i32.const 2
    i32.store offset=4
    local.get $__mem0
    local.set $a
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 1
    i32.store
    local.get $__mem1
    i32.const 2
    i32.store offset=4
    local.get $__mem1
    local.set $b
    local.get $a
    local.get $b
    i32.eq
    return
  )
  (func $arrayEq (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $xs i32)
    (local $ys i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 1
    i32.store
    local.get $__mem0
    i32.const 2
    i32.store offset=4
    local.get $__mem0
    local.set $xs
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 1
    i32.store
    local.get $__mem1
    i32.const 2
    i32.store offset=4
    local.get $__mem1
    local.set $ys
    local.get $xs
    local.get $ys
    i32.eq
    return
  )
)
```

----- RUN LOG -----
```logs
```
