----- SOURCE CODE -- main.bp
```botopink
val Point = struct {
    x: i32,
    y: i32,
    fn sum() -> i32 {
        return self.x + self.y;
    }
};
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $Point_sum (param $self i32) (result i32)
    local.get $self
    i32.load ;; .x
    local.get $self
    i32.load offset=4 ;; .y
    i32.add
    return
  )
)
```

----- RUN LOG -----
```logs
```
