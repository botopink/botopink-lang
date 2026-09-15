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
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; cross-module import not linked (wasm single-module): PORT from config
  ;; cross-module import not linked (wasm single-module): HOST from config
  (global $addr (mut i32) (i32.const 0))
  (global $port (mut i32) (i32.const 0))
)
```

----- RUN LOG -----
```logs
```
