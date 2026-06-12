----- SOURCE CODE -- main.bp
```botopink
record Pipeline {
    items: i32[],
    fn doubled(self: Self) -> i32[] {
        return List.map(self.items) { x ->
            return x * 2;
        };
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
)
```

----- RUN LOG -----
```logs
```
