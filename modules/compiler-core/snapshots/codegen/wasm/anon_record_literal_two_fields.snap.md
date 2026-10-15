----- SOURCE CODE -- main.bp
```botopink
fn make() -> #(i32, i32) {
    val r = #(7, 11);
    return r;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_any (array (mut anyref)))
    (type $box_i32 (struct (field $v i32)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $make (result (ref null $arr_any))
    (local $__mem0 i32)
    (local $r (ref null $arr_any))
    i32.const 7
    struct.new $box_i32
    i32.const 11
    struct.new $box_i32
    array.new_fixed $arr_any 2
    local.set $r
    local.get $r
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
