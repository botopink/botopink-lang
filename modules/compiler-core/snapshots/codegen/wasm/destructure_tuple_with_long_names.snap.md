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
  (rec
    (type $str (array (mut i8)))
    (type $box_f64 (struct (field $v f64)))
    (type $arr_any (sub (array (mut anyref))))
    (type $tuple (sub final $arr_any (array (mut anyref))))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $get_coordinates (result (ref null $arr_any))
    (local $__mem0 i32)
    f64.const 0.0
    struct.new $box_f64
    f64.const 0.0
    struct.new $box_f64
    array.new_fixed $tuple 2
    return
  )
  (func $extract_coordinates
    (local $__mem0 i32)
    (local $longitude f64)
    (local $latitude f64)
    (local $__gc0 (ref null $arr_any))
    call $get_coordinates
    local.set $__gc0
    local.get $__gc0
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    local.set $longitude
    local.get $__gc0
    i32.const 1
    array.get $arr_any
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    local.set $latitude
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
