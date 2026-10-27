----- SOURCE CODE -- main.bp
```botopink
type R(a: i32, b: i32)
fn pick(maybe: ?R) -> ?i32 {
    return maybe?.b;
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
    (type $rec_R (struct (field $f0 (mut i32)) (field $f1 (mut i32))))
    (type $brand_rec_R (struct (field i64) (field i64) (field i32) (field i32) (field f32) (field i32) (field i64) (field i64) (field i64) (field f32) (field i64) (field f64) (field i32) (field i64) (field i64) (field i64) (field f64) (field f64) (field i32) (field i32) (field f64) (field f64) (field i64) (field f32) (field f64) (field f64) (field i32) (field f64) (field i32) (field i32) (field f64) (field i64)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $pick (param $maybe (ref null $rec_R)) (result anyref)
    (local $__mem0 i32)
    (local $__gc0 (ref null $rec_R))
    local.get $maybe
    local.tee $__gc0
    ref.is_null
    (if (result anyref)
      (then
    ref.null any
      )
      (else
    local.get $__gc0
    struct.get $rec_R $f1
    struct.new $box_i32
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
