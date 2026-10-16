----- SOURCE CODE -- main.bp
```botopink
fn make() -> #(#(i32, i32), i32) {
    val outer = #(#(1, 2), 3);
    return outer;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_any (sub (array (mut anyref))))
    (type $box_i32 (struct (field $v i32)))
    (type $tuple (sub final $arr_any (array (mut anyref))))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $make (result (ref null $arr_any))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $outer (ref null $arr_any))
    i32.const 1
    struct.new $box_i32
    i32.const 2
    struct.new $box_i32
    array.new_fixed $tuple 2
    i32.const 3
    struct.new $box_i32
    array.new_fixed $tuple 2
    local.set $outer
    local.get $outer
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
