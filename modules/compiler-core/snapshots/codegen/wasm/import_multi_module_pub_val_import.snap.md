----- SOURCE CODE -- config.bp
```botopink
pub val PORT = 8080;
pub val HOST = "localhost";
```

----- WASM TEXT -- config.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
  )
  (memory (export "memory") 1)
  (start $__init_strs)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $PORT (export "PORT") i32 (i32.const 8080))
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

----- SOURCE CODE -- main.bp
```botopink
import {config.PORT, config.HOST};
val addr = HOST;
val port = PORT;
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
  (global $PORT i32 (i32.const 8080))
  (global $HOST (mut (ref null $str)) (ref.null $str))
  (global $addr (mut (ref null $str)) (ref.null $str))
  (global $port (mut i32) (i32.const 0))
  (func $__init_globals
    global.get $__s0
    global.set $HOST
    global.get $HOST
    global.set $addr
    global.get $PORT
    global.set $port
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
