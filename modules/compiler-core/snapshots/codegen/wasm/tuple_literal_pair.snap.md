----- SOURCE CODE -- main.bp
```botopink
val pair = #(1, "hello");
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
  (start $__init_strs)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $pair (mut (ref null $arr_any)) (ref.null $arr_any))
  (func $__init_globals
    (local $__mem0 i32)
    i32.const 1
    struct.new $box_i32
    global.get $__s0
    array.new_fixed $tuple 2
    global.set $pair
  )
  (data $__d0 "hello")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (func $__init_strs
    i32.const 0
    i32.const 5
    array.new_data $str $__d0
    global.set $__s0
    call $__init_globals
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
