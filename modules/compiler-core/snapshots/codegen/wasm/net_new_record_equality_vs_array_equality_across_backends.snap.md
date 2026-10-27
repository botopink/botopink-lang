----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
fn recordEq() -> bool {
    val a = Point(x: 1, y: 2);
    val b = Point(x: 1, y: 2);
    return a == b;
}
fn arrayEq() -> bool {
    val xs = [1, 2];
    val ys = [1, 2];
    return xs == ys;
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
    (type $rec_Point (struct (field $f0 (mut i32)) (field $f1 (mut i32))))
    (type $brand_rec_Point (struct (field i64) (field i64) (field i64) (field f64) (field i64) (field f64) (field i64) (field i64) (field i32) (field f64) (field f32) (field f64) (field i32) (field i64) (field f32) (field f32) (field i64) (field i64) (field i64) (field i32) (field i32) (field f32) (field f64) (field f64) (field i32) (field i32) (field i32) (field f64) (field f32) (field f32) (field f32) (field f32)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $recordEq (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $a (ref null $rec_Point))
    (local $b (ref null $rec_Point))
    i32.const 1
    i32.const 2
    struct.new $rec_Point
    local.set $a
    i32.const 1
    i32.const 2
    struct.new $rec_Point
    local.set $b
    local.get $a
    local.get $b
    call $__eq_Point
    return
  )
  (func $arrayEq (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $xs (ref null $arr_i32))
    (local $ys (ref null $arr_i32))
    i32.const 1
    i32.const 2
    array.new_fixed $arr_i32 2
    local.set $xs
    i32.const 1
    i32.const 2
    array.new_fixed $arr_i32 2
    local.set $ys
    local.get $xs
    local.get $ys
    call $__eq_Array_i32
    return
  )
  (func $__eq_Point (param $a (ref null $rec_Point)) (param $b (ref null $rec_Point)) (result i32)
    local.get $a
    struct.get $rec_Point $f0
    local.get $b
    struct.get $rec_Point $f0
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    struct.get $rec_Point $f1
    local.get $b
    struct.get $rec_Point $f1
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    i32.const 1
  )
  (func $__eq_Array_i32 (param $a (ref null $arr_i32)) (param $b (ref null $arr_i32)) (result i32)
    (local $n i32)
    (local $i i32)
    local.get $a
    array.len
    local.get $b
    array.len
    i32.ne
    (if
      (then i32.const 0 return)
    )
    local.get $a
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $a
    local.get $i
    array.get $arr_i32
    local.get $b
    local.get $i
    array.get $arr_i32
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    i32.const 1
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
