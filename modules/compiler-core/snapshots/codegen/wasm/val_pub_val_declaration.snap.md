----- SOURCE CODE -- main.bp
```botopink
pub val VERSION = 1;
pub val HOST = "localhost";
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
  (global $VERSION (export "VERSION") i32 (i32.const 1))
  (global $HOST (mut (ref null $str)) (ref.null $str))
  (func $__init_globals
    global.get $__s0
    global.set $HOST
  )
  (data $__d0 "localhost")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (func $__init_strs
    i32.const 0
    i32.const 9
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
