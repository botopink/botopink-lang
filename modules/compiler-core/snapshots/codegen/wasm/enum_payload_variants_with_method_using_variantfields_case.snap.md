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
    (type $arr_i32 (array (mut i32)))
    (type $arr_f64 (array (mut f64)))
    (type $arr_any (sub (array (mut anyref))))
    (type $tuple (sub final $arr_any (array (mut anyref))))
    (type $box_i32 (sub (struct (field $v i32))))
    (type $box_i64 (struct (field $v i64)))
    (type $box_f64 (struct (field $v f64)))
    (type $box_bool (sub final $box_i32 (struct (field $v i32))))
    (type $box_big (struct (field $v (ref null $str))))
    (type $closure (sub (struct (field $idx i32) (field $mark i32))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $exn (struct (field $msg (ref null $str)) (field $print i32)))
    (type $task (struct (field $state (mut i32)) (field $waiters (mut (ref null $waiter))) (field $value (mut anyref)) (field $frame (mut structref)) (field $kind i32) (field $next (mut (ref null $task))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $waiter (struct (field $next (mut (ref null $waiter))) (field $kind i32) (field $target (ref null $task)) (field $slot i32)))
    (type $hostn (struct (field $next (mut (ref null $hostn))) (field $h i32) (field $t (ref null $task))))
    (type $gen (struct (field $state (mut i32)) (field $kind i32) (field $frame (mut structref)) (field $value (mut anyref)) (field $src (mut (ref null $gen))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $cell (struct (field $filled (mut i32)) (field $value (mut anyref))))
  )
  (rec
    (type $var_Shape_Circle (struct (field $f0 (mut f64))))
    (type $brand_var_Shape_Circle (struct (field i64) (field i32) (field i64) (field i32) (field f32) (field i64) (field i64) (field f64) (field i64) (field i64) (field i32) (field f64) (field i64) (field f32) (field f32) (field f64) (field i64) (field f32) (field i32) (field i64) (field f64) (field f32) (field f64) (field f32) (field i64) (field i32) (field i32) (field f32) (field f64) (field i32) (field i64) (field i32)))
  )
  (rec
    (type $var_Shape_Square (struct (field $f0 (mut f64))))
    (type $brand_var_Shape_Square (struct (field i32) (field i64) (field i32) (field i64) (field i64) (field i64) (field i64) (field f32) (field f64) (field i64) (field f64) (field i64) (field f64) (field f32) (field f64) (field i64) (field i32) (field i32) (field i64) (field i64) (field i64) (field f64) (field i64) (field i64) (field f32) (field f64) (field i32) (field f32) (field f32) (field f64) (field f64) (field f32)))
  )
  (rec
    (type $var_Shape_Triangle (struct (field $f0 (mut f64)) (field $f1 (mut f64))))
    (type $brand_var_Shape_Triangle (struct (field i64) (field f32) (field i64) (field f32) (field f64) (field i64) (field f32) (field i32) (field i32) (field i64) (field i64) (field i32) (field f32) (field i32) (field f32) (field f32) (field i32) (field f64) (field f32) (field i32) (field f64) (field i64) (field i64) (field f64) (field f64) (field i64) (field i32) (field f32) (field i32) (field i64) (field f64) (field f32)))
  )
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
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
