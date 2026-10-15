----- SOURCE CODE -- main.bp
```botopink
fn main() {
    var #(x, y) = #(10, 20);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $box_i32 (struct (field $v i32)))
    (type $arr_any (array (mut anyref)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $main
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $x i32)
    (local $y i32)
    (local $__gc0 (ref null $arr_any))
    i32.const 10
    struct.new $box_i32
    i32.const 20
    struct.new $box_i32
    array.new_fixed $arr_any 2
    local.set $__gc0
    local.get $__gc0
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $x
    local.get $__gc0
    i32.const 1
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $y
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
