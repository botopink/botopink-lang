----- SOURCE CODE -- main.bp
```botopink
val Shape = type {
    Circle(radius: f64),
    Square(side: f64),
    Triangle(base: f64, height: f64),
    fn area(shape: Self) -> f64 {
        return case shape {
            Circle(radius) -> radius * radius * 3.14;
            Square(side) -> side * side;
            Triangle(base, height) -> base * height * 0.5;
            _ -> 0.0;
        };
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $Shape_area (param $shape i32) (result i32)
    (local $radius f64)
    (local $side f64)
    (local $base f64)
    (local $height f64)
    (local $__case_0 i32)
    local.get $shape
    local.set $__case_0
    local.get $__case_0
    i32.load ;; variant tag
    i32.const 0 ;; Circle
    i32.eq
    (if (result i32)
      (then
    local.get $__case_0
    f32.load offset=4
    f64.promote_f32
    local.set $radius
    local.get $radius
    local.get $radius
    f64.mul
    f32.const 3.14
    f64.promote_f32
    f64.mul
    i32.trunc_f64_s
      )
      (else
    local.get $__case_0
    i32.load ;; variant tag
    i32.const 1 ;; Square
    i32.eq
    (if (result i32)
      (then
    local.get $__case_0
    f32.load offset=4
    f64.promote_f32
    local.set $side
    local.get $side
    local.get $side
    f64.mul
    i32.trunc_f64_s
      )
      (else
    local.get $__case_0
    i32.load ;; variant tag
    i32.const 2 ;; Triangle
    i32.eq
    (if (result i32)
      (then
    local.get $__case_0
    f32.load offset=4
    f64.promote_f32
    local.set $base
    local.get $__case_0
    f32.load offset=8
    f64.promote_f32
    local.set $height
    local.get $base
    local.get $height
    f64.mul
    f32.const 0.5
    f64.promote_f32
    f64.mul
    i32.trunc_f64_s
      )
      (else
    f32.const 0.0
    i32.trunc_f32_s
      )
    )
      )
    )
      )
    )
    return
  )
)
```

----- RUN LOG -----
```logs
```
