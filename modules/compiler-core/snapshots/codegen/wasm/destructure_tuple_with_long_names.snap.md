----- SOURCE CODE -- main.bp
```botopink
fn get_coordinates() -> #(f32, f32) {
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
    f32.const 0.0
    i32.store
    local.get $__mem0
    f32.const 0.0
    i32.store offset=4
    local.get $__mem0
    return
  )
  (func $extract_coordinates
    (local $__mem0 i32)
    (local $longitude i32)
    (local $latitude i32)
    call $get_coordinates
    local.set $__mem0
    local.get $__mem0
    i32.load
    local.set $longitude
    local.get $__mem0
    i32.load offset=4
    local.set $latitude
  )
)
```

----- RUN LOG -----
```logs
```
