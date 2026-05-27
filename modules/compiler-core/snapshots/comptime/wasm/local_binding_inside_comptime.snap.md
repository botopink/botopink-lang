----- SOURCE CODE -- main.bp
```botopink
val hash = comptime { break 6364 + 11; };
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
(module
  (import "wasi_snapshot_preview1" "fd_write"
    (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 8) "[{\"id\":\"ct_0\",\"value\":6375}]")
  (func $main (export "_start")
    (i32.store (i32.const 0) (i32.const 8))
    (i32.store (i32.const 4) (i32.const 28))
    (drop (call $fd_write (i32.const 1) (i32.const 0) (i32.const 1) (i32.const 200))))
)

```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val hash = comptime {
    break 6364 + 11;
};
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "hash",
      "return_type": "void"
    }
  ]
}
```

