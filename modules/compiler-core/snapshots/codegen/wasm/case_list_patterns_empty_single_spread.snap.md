----- SOURCE CODE -- main.bp
```botopink
fn describe() -> string {
    val items = ["a", "b", "c"];
    return case items {
        [] -> "empty";
        [x] -> "one";
        [first, ..rest] -> "many";
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_i32 (sub (array (mut i32))))
    (type $arr_bool (sub final $arr_i32 (array (mut i32))))
    (type $arr_f64 (array (mut f64)))
    (type $arr_any (sub (array (mut anyref))))
    (type $tuple (sub final $arr_any (array (mut anyref))))
    (type $box_i32 (sub (struct (field $v i32))))
    (type $box_i64 (struct (field $v i64)))
    (type $box_f64 (struct (field $v f64)))
    (type $box_bool (sub final $box_i32 (struct (field $v i32))))
    (type $box_big (struct (field $v (ref null $str))))
    (type $closure (sub (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $exn (struct (field $msg (ref null $str)) (field $print i32)))
    (type $task (struct (field $state (mut i32)) (field $waiters (mut (ref null $waiter))) (field $value (mut anyref)) (field $frame (mut structref)) (field $kind i32) (field $next (mut (ref null $task))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $waiter (struct (field $next (mut (ref null $waiter))) (field $kind i32) (field $target (ref null $task)) (field $slot i32)))
    (type $hostn (struct (field $next (mut (ref null $hostn))) (field $h i32) (field $t (ref null $task))))
    (type $gen (struct (field $state (mut i32)) (field $kind i32) (field $frame (mut structref)) (field $value (mut anyref)) (field $src (mut (ref null $gen))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $cell (struct (field $filled (mut i32)) (field $value (mut anyref))))
    (type $__decl (sub (struct (field $ti (ref null $__tinfo)))))
    (type $__tinfo (struct (field $name (ref null $str)) (field $print funcref) (field $eq funcref) (field $display funcref) (field $kind i32)))
    (type $__print_sig (func (param anyref)))
    (type $__eq_sig (func (param anyref anyref) (result i32)))
  )
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $describe (result (ref null $str))
    (local $__mem0 i32)
    (local $items (ref null $arr_any))
    (local $x i32)
    (local $first i32)
    (local $rest i32)
    (local $__case_0 (ref null $arr_any))
    (local $x__0 (ref null $str))
    (local $first__1 (ref null $str))
    (local $rest__2 (ref null $arr_any))
    global.get $__s0
    global.get $__s1
    global.get $__s2
    array.new_fixed $arr_any 3
    local.set $items
    local.get $items
    local.set $__case_0
    local.get $__case_0
    array.len
    i32.const 0
    i32.eq
    (if (result (ref null $str))
      (then
    global.get $__s3
      )
      (else
    local.get $__case_0
    array.len
    i32.const 1
    i32.eq
    (if (result (ref null $str))
      (then
    local.get $__case_0
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $str)
    local.set $x__0
    global.get $__s4
      )
      (else
    local.get $__case_0
    array.len
    i32.const 1
    i32.ge_u
    (if (result (ref null $str))
      (then
    local.get $__case_0
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $str)
    local.set $first__1
    local.get $__case_0
    i32.const 1
    i32.const 2147483647
    call $__arr_slice_any
    local.set $rest__2
    global.get $__s5
      )
      (else
    ref.null $str
      )
    )
      )
    )
      )
    )
    return
  )
  (func $__arr_slice_any (param $xs (ref null $arr_any)) (param $a i32) (param $b i32) (result (ref null $arr_any))
    (local $len i32)
    (local $from i32)
    (local $to i32)
    (local $n i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $len
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $len
    local.get $a
    i32.add
    local.set $from
    local.get $from
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $from
      )
    )
      )
      (else
    local.get $a
    local.set $from
    local.get $from
    local.get $len
    i32.gt_s
    (if
      (then
    local.get $len
    local.set $from
      )
    )
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $len
    local.get $b
    i32.add
    local.set $to
    local.get $to
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $to
      )
    )
      )
      (else
    local.get $b
    local.set $to
    local.get $to
    local.get $len
    i32.gt_s
    (if
      (then
    local.get $len
    local.set $to
      )
    )
      )
    )
    local.get $to
    local.get $from
    i32.sub
    local.set $n
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $n
      )
    )
    local.get $n
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    local.get $from
    local.get $n
    array.copy $arr_any $arr_any
    local.get $r
  )
  (data $__d0 "a")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "b")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "c")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "empty")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "one")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "many")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 1
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 1
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 1
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 5
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 3
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 4
    array.new_data $str $__d5
    global.set $__s5
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
