----- SOURCE CODE -- main.bp
```botopink
val result = case 42 {
    0 -> {
      case 1 {
          0    -> 54;
          _ -> 1;
      };
   };
   _ -> 1;
};
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $result (mut i32) (i32.const 0))
)
```

----- RUN LOG -----
```logs
```
