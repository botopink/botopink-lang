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
  (rec
    (type $str (array (mut i8)))
    (type $var_Shape_Circle (struct (field $f0 (mut f64))))
    (type $var_Shape_Square (struct (field $f0 (mut f64))))
    (type $var_Shape_Triangle (struct (field $f0 (mut f64)) (field $f1 (mut f64))))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $Shape_area (param $shape anyref) (result f64)
    (local $radius f64)
    (local $side f64)
    (local $base f64)
    (local $height f64)
    (local $__case_0 anyref)
    local.get $shape
    local.set $__case_0
    local.get $__case_0
    ref.test (ref null $var_Shape_Circle)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result f64)
      (then
    local.get $__case_0
    ref.cast (ref null $var_Shape_Circle)
    struct.get $var_Shape_Circle $f0
    local.set $radius
    local.get $radius
    local.get $radius
    f64.mul
    f64.const 3.14
    f64.mul
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_Shape_Square)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result f64)
      (then
    local.get $__case_0
    ref.cast (ref null $var_Shape_Square)
    struct.get $var_Shape_Square $f0
    local.set $side
    local.get $side
    local.get $side
    f64.mul
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_Shape_Triangle)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result f64)
      (then
    local.get $__case_0
    ref.cast (ref null $var_Shape_Triangle)
    struct.get $var_Shape_Triangle $f0
    local.set $base
    local.get $__case_0
    ref.cast (ref null $var_Shape_Triangle)
    struct.get $var_Shape_Triangle $f1
    local.set $height
    local.get $base
    local.get $height
    f64.mul
    f64.const 0.5
    f64.mul
      )
      (else
    f64.const 0.0
      )
    )
      )
    )
      )
    )
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
