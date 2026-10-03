----- SOURCE CODE -- main.bp
```botopink
fn get_coordinates() -> #(f64, f64) {
    return #(0.0, 0.0);
}
fn extract_coordinates() {
    val #(longitude, latitude) = get_coordinates();
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $get_coordinates (result i32)
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    f64.const 0.0
    call $__box_f64
    i32.store
    local.get $__mem0
    f64.const 0.0
    call $__box_f64
    i32.store offset=4
    local.get $__mem0
    return
  )
  (func $extract_coordinates
    (local $__mem0 i32)
    (local $longitude f64)
    (local $latitude f64)
    call $get_coordinates
    local.set $__mem0
    local.get $__mem0
    i32.load
    f64.load
    local.set $longitude
    local.get $__mem0
    i32.load offset=4
    f64.load
    local.set $latitude
  )
  (func $__alloc (param $n i32) (result i32)
    (local $p i32)
    global.get $__heap_ptr
    local.set $p
    global.get $__heap_ptr
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    global.set $__heap_ptr
    local.get $p
  )
  (func $__box_f64 (param $x f64) (result i32)
    (local $p i32)
    i32.const 8
    call $__alloc
    local.tee $p
    local.get $x
    f64.store
    local.get $p
  )
)
```

----- RUN LOG -----
```logs
```
