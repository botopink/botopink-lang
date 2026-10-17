----- SOURCE CODE -- main.bp
```botopink
val greeting = "hello";
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
  )
  (memory (export "memory") 1)
  (start $__init_strs)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $greeting (mut (ref null $str)) (ref.null $str))
  (func $__init_globals
    global.get $__s0
    global.set $greeting
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
