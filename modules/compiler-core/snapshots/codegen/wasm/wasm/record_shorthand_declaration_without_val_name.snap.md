----- SOURCE CODE -- main.bp
```botopink
record Vec2 {
    x: f64,
    y: f64,
    fn dot(self: Self, other: Vec2) -> f64 {
        return self.x * other.x + self.y * other.y;
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $Vec2_dot (param $self i32) (param $other i32) (result i32)
    local.get $self
    i32.load ;; .x
    local.get $other
    i32.load ;; .x
    i32.mul
    local.get $self
    i32.load offset=4 ;; .y
    local.get $other
    i32.load offset=4 ;; .y
    i32.mul
    i32.add
    return
  )
)
```

----- RUN LOG -----
```logs
```
