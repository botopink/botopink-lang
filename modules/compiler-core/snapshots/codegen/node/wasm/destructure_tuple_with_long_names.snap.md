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
    i32.const 0 ;; tuple
    return
  )
  (func $extract_coordinates
    (local $longitude i32)
    (local $latitude i32)
    call $get_coordinates
    local.set $latitude
    local.set $longitude
  )
)
```

----- RUN LOG -----
```logs
```
