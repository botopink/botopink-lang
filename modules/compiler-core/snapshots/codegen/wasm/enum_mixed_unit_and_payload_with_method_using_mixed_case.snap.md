----- SOURCE CODE -- main.bp
```botopink
val Maybe = type {
    Nothing,
    Just(value: string),
    fn check(m: Self) -> string {
        return case m {
            Nothing -> "nothing";
            Just(value) -> "just";
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
    (type $var_Maybe_Just (struct (field $f0 (mut (ref null $str)))))
    (type $brand_var_Maybe_Just (struct (field i64) (field f32) (field i64) (field f32) (field i64) (field i32) (field f32) (field i32) (field i64) (field f32) (field i64) (field f32) (field f64) (field f64) (field f64) (field f64) (field i32) (field f32) (field i32) (field f64) (field f32) (field f64) (field i32) (field i64) (field i32) (field f64) (field i32) (field f32) (field f64) (field f32) (field i64) (field f64)))
  )
  (rec
    (type $var_Maybe_Nothing (struct))
    (type $brand_var_Maybe_Nothing (struct (field i64) (field f64) (field i64) (field f32) (field f64) (field f32) (field i32) (field f64) (field f64) (field f32) (field f32) (field i32) (field i64) (field f64) (field f32) (field f32) (field f32) (field f32) (field i64) (field f32) (field f32) (field f32) (field f32) (field f32) (field i64) (field f32) (field f64) (field i64) (field f64) (field f32) (field i32) (field f64)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $Maybe_check (param $m anyref) (result (ref null $str))
    (local $value (ref null $str))
    (local $__case_0 anyref)
    local.get $m
    local.set $__case_0
    local.get $__case_0
    ref.test (ref null $var_Maybe_Nothing)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    global.get $__s0
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_Maybe_Just)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_Maybe_Just)
    struct.get $var_Maybe_Just $f0
    local.set $value
    global.get $__s1
      )
      (else
    ref.null $str
      )
    )
      )
    )
    return
  )
  (data $__d0 "nothing")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "just")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 7
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 4
    array.new_data $str $__d1
    global.set $__s1
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
