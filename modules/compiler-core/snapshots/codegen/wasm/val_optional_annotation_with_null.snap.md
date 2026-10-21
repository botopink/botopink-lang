----- SOURCE CODE -- main.bp
```botopink
val msg: ?string = null;
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
  )
  (memory (export "memory") 1)
  (start $__init_globals)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $msg (mut (ref null $str)) (ref.null $str))
  (func $__init_globals
    ref.null $str
    global.set $msg
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
