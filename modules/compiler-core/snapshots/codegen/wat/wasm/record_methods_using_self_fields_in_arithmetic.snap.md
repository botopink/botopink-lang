----- SOURCE CODE -- main.bp
```botopink
val Vec2 = type(
    x: f64,
    y: f64) {
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
  (func $Vec2_lengthSq (param $self i32) (result f64)
    local.get $self
    i32.load ;; .x
    f64.load
    local.get $self
    i32.load ;; .x
    f64.load
    f64.mul
    local.get $self
    i32.load offset=4 ;; .y
    f64.load
    local.get $self
    i32.load offset=4 ;; .y
    f64.load
    f64.mul
    f64.add
    return
  )
  (func $Vec2_scale (param $self i32) (param $factor f64) (result f64)
    local.get $self
    i32.load ;; .x
    f64.load
    local.get $factor
    f64.mul
    return
  )
)
```

----- RUN LOG -----
```logs
```
