----- SOURCE CODE -- main.bp
```botopink
val items: string[] = ["65454"];
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_any (array (mut anyref)))
  )
  (memory (export "memory") 1)
  (start $__init_strs)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $items (mut (ref null $arr_any)) (ref.null $arr_any))
  (func $__init_globals
    (local $__mem0 i32)
    global.get $__s0
    array.new_fixed $arr_any 1
    global.set $items
  )
  (data $__d0 "65454")
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
