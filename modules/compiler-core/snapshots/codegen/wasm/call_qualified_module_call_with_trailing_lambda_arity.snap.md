----- SOURCE CODE -- main.bp
```botopink
type List(tag: i32) {
    fn each(items: i32[], f: fn() -> i32) -> i32[] {
        return items;
    }
}
type Pipeline(
    items: i32[]) {
    fn doubled(self: Self) -> i32[] {
        return List.each(self.items) { ->
            return 2;
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
    (type $rec_Pipeline (struct (field $f0 (mut (ref null $arr_i32)))))
    (type $brand_rec_Pipeline (struct (field f32) (field i32) (field i64) (field f64) (field f64) (field i32) (field f64) (field i64) (field i64) (field f64) (field f32) (field f64) (field i32) (field f32) (field i64) (field f64) (field i64) (field f64) (field f32) (field f32) (field i64) (field i64) (field i32) (field f32) (field f64) (field i64) (field f64) (field i64) (field f64) (field i64) (field i64) (field f32)))
  )
  (rec
    (type $env0 (sub final $closure (struct (field $idx i32) (field $mark i32))))
  )
  (memory (export "memory") 1)
  (table funcref (elem $__lambda0))
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $List_each (param $items (ref null $arr_i32)) (param $f (ref null $closure)) (result (ref null $arr_i32))
    local.get $items
    return
  )
  (func $Pipeline_doubled (param $self (ref null $rec_Pipeline)) (result (ref null $arr_i32))
    local.get $self
    struct.get $rec_Pipeline $f0
    i32.const 0
    i32.const 0
    struct.new $env0
    call $List_each
    return
  )
  (func $__lambda0__b (param $__env (ref null $env0)) (result i32)
    i32.const 2
    return
  )
  (func $__lambda0 (param $__env (ref null $closure)) (result anyref)
    local.get $__env
    ref.cast (ref null $env0)
    call $__lambda0__b
    struct.new $box_i32
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
