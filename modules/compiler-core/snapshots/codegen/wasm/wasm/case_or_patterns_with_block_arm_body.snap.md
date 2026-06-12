----- SOURCE CODE -- main.bp
```botopink
val parity = case 5 {
    0 | 2 | 4 -> "even";
    _      -> {
        val value = "odd";
        break value;
    };
};
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $parity (mut i32) (i32.const 0))
)
```

----- RUN LOG -----
```logs
```
