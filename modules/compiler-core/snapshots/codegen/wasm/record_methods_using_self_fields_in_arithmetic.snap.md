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
  (rec
    (type $str (array (mut i8)))
    (type $rec_Vec2 (struct (field $f0 (mut f64)) (field $f1 (mut f64))))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $Vec2_lengthSq (param $self (ref null $rec_Vec2)) (result f64)
    local.get $self
    struct.get $rec_Vec2 $f0
    local.get $self
    struct.get $rec_Vec2 $f0
    f64.mul
    local.get $self
    struct.get $rec_Vec2 $f1
    local.get $self
    struct.get $rec_Vec2 $f1
    f64.mul
    f64.add
    return
  )
  (func $Vec2_scale (param $self (ref null $rec_Vec2)) (param $factor f64) (result f64)
    local.get $self
    struct.get $rec_Vec2 $f0
    local.get $factor
    f64.mul
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
