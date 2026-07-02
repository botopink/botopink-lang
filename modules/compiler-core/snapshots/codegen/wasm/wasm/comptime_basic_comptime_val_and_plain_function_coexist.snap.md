----- SOURCE CODE -- main.bp
```botopink
val x = comptime 1 + 2;

fn double(n: i32) -> i32 {
    return n * 2;
}

fn main() {
    val r = double(21);
}
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
-module(comptime_45af6ab6cf9e497c).
-export([main/0]).
main() -> "[{\"id\":\"ct_0\",\"value\":3}]".
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $double (param $n i32) (result i32)
    local.get $n
    i32.const 2
    i32.mul
    return
  )
  (func $main
    (local $r i32)
    i32.const 21
    call $double
    local.set $r
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
)
```

----- RUN LOG -----
```logs
```
