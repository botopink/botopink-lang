----- SOURCE CODE -- main.bp
```botopink
val Vec2 = record {
    x: f64,
    y: f64,
    fn lengthSq(self: Self) -> f64 {
        return self.x * self.x + self.y * self.y;
    }
    fn scale(self: Self, factor: f64) -> f64 {
        return self.x * factor;
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $Vec2_lengthSq (param $self i32) (result i32)
    local.get $self
    i32.load ;; .x
    local.get $self
    i32.load ;; .x
    i32.mul
    local.get $self
    i32.load offset=4 ;; .y
    local.get $self
    i32.load offset=4 ;; .y
    i32.mul
    i32.add
    return
  )
  (func $Vec2_scale (param $self i32) (param $factor i32) (result i32)
    local.get $self
    i32.load ;; .x
    local.get $factor
    i32.mul
    return
  )
)
```

----- RUN LOG -----
```logs
```
