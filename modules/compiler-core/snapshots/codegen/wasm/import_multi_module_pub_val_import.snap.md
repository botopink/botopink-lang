----- SOURCE CODE -- config.bp
```botopink
pub val PORT = 8080;
pub val HOST = "localhost";
```

----- WASM TEXT -- config.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\09\00\00\00localhost")
  (global $__heap_ptr (mut i32) (i32.const 272))
  (global $PORT (export "PORT") i32 (i32.const 8080))
  (global $HOST (mut i32) (i32.const 256))
)
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {PORT, HOST} from "config";
val addr = HOST;
val port = PORT;
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (start $__init_globals)
  (data (i32.const 256) "\09\00\00\00localhost")
  (global $__heap_ptr (mut i32) (i32.const 272))
  (global $PORT i32 (i32.const 8080))
  (global $HOST (mut i32) (i32.const 256))
  (global $addr (mut i32) (i32.const 0))
  (global $port (mut i32) (i32.const 0))
  (func $__init_globals
    global.get $HOST
    global.set $addr
    global.get $PORT
    global.set $port
  )
)
```

----- RUN LOG -----
```logs
```
