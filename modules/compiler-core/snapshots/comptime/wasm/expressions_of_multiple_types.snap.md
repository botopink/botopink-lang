----- SOURCE CODE -- main.bp
```botopink
val pi      = comptime 3.14 * 2.0;
val maxVal  = comptime 100 + 1;
val banner  = comptime "Hello, " + "World";
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
(module
  (import "wasi_snapshot_preview1" "fd_write"
    (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 8) "[{\"id\":\"ct_0\",\"value\":0},{\"id\":\"ct_1\",\"value\":101},{\"id\":\"ct_2\",\"value\":0}]")
  (func $main (export "_start")
    (i32.store (i32.const 0) (i32.const 8))
    (i32.store (i32.const 4) (i32.const 75))
    (drop (call $fd_write (i32.const 1) (i32.const 0) (i32.const 1) (i32.const 200))))
)

```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val pi = 0;

val maxVal = 101;

val banner = 0;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "pi",
      "return_type": "f64"
    },
    {
      "ast": "val",
      "indent": "maxVal",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "indent": "banner",
      "return_type": "string"
    }
  ]
}
```

