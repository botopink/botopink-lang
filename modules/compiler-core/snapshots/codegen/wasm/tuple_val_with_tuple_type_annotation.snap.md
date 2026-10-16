----- SOURCE CODE -- main.bp
```botopink
val t: #(string, string) = #("56454", "85484");
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_any (sub (array (mut anyref))))
    (type $tuple (sub final $arr_any (array (mut anyref))))
  )
  (memory (export "memory") 1)
  (start $__init_strs)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $t (mut (ref null $arr_any)) (ref.null $arr_any))
  (func $__init_globals
    (local $__mem0 i32)
    global.get $__s0
    global.get $__s1
    array.new_fixed $tuple 2
    global.set $t
  )
  (data $__d0 "56454")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "85484")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (func $__init_strs
    i32.const 0
    i32.const 5
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 5
    array.new_data $str $__d1
    global.set $__s1
    call $__init_globals
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
