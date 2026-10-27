----- SOURCE CODE -- main.bp
```botopink
val nothing = null;
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (start $__init_globals)
  (global $nothing (mut i32) (i32.const 0))
  (func $__init_globals
    i32.const 0
    global.set $nothing
  )
)
```

----- RUN LOG -----
```logs
```
