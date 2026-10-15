----- SOURCE CODE -- main.bp
```botopink
type Vec2(
    x: f64,
    y: f64) {
    fn dot(self: Self, other: Vec2) -> f64 {
        return self.x * other.x + self.y * other.y;
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
  (func $Vec2_dot (param $self (ref null $rec_Vec2)) (param $other (ref null $rec_Vec2)) (result f64)
    local.get $self
    struct.get $rec_Vec2 $f0
    local.get $other
    struct.get $rec_Vec2 $f0
    f64.mul
    local.get $self
    struct.get $rec_Vec2 $f1
    local.get $other
    struct.get $rec_Vec2 $f1
    f64.mul
    f64.add
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
