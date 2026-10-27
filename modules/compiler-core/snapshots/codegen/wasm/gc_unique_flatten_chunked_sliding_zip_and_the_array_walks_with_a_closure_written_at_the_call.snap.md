----- SOURCE CODE -- main.bp
```botopink
pub fn main() -> void {
    val xs = [3, 1, 3, 2, 1];
    print(xs.unique());
    print(["a", "b", "a"].unique());
    print([[1, 2], [3]].flatten());
    print(xs.chunked(2));
    print(xs.sliding(3));
    print(xs.map({ x -> x * 2 }));
    print(xs.filter({ x -> x > 1 }));
    print(xs.fold(0, { acc, x -> acc + x }));
    print(xs.any({ x -> x == 2 }), xs.all({ x -> x > 0 }), xs.count({ x -> x == 3 }));
    print(["a", "bb"].map({ s -> s.length() }));
    print(xs.zip(["a", "b"]));
}

import {io.terminal.print} from "std";
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
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@string" "wat:text.length" (func $__abi___std_text_length (param arrayref) (result i32)))
  (import "std@number" "wat:number.i64ToString" (func $__abi___std_number_i64ToString (param i64) (result arrayref)))
  (import "std@number" "wat:number.u64ToString" (func $__abi___std_number_u64ToString (param i64) (result arrayref)))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $main (export "main")
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    (local $__mem5 i32)
    (local $__mem6 i32)
    (local $xs (ref null $arr_i32))
    (local $__iter0 (ref null $arr_i32))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $x i32)
    (local $__out0 (ref null $arr_i32))
    (local $__iter1 (ref null $arr_i32))
    (local $__idx1 i32)
    (local $__len1 i32)
    (local $__acc1 i32)
    (local $__out1 (ref null $arr_i32))
    (local $__iter2 (ref null $arr_i32))
    (local $__idx2 i32)
    (local $__len2 i32)
    (local $__acc2 i32)
    (local $acc i32)
    (local $__iter3 (ref null $arr_i32))
    (local $__idx3 i32)
    (local $__len3 i32)
    (local $__acc3 i32)
    (local $__iter4 (ref null $arr_i32))
    (local $__idx4 i32)
    (local $__len4 i32)
    (local $__acc4 i32)
    (local $__iter5 (ref null $arr_i32))
    (local $__idx5 i32)
    (local $__len5 i32)
    (local $__acc5 i32)
    (local $__iter6 (ref null $arr_any))
    (local $__idx6 i32)
    (local $__len6 i32)
    (local $__acc6 i32)
    (local $s (ref null $str))
    (local $__out6 (ref null $arr_i32))
    i32.const 3
    i32.const 1
    i32.const 3
    i32.const 2
    i32.const 1
    array.new_fixed $arr_i32 5
    local.set $xs
    local.get $xs
    call $__arr_unique_i32
    call $__pr0
    call $__print_nl
    global.get $__s3
    global.get $__s4
    global.get $__s3
    array.new_fixed $arr_any 3
    call $__arr_unique_any
    call $__pr2
    call $__print_nl
    i32.const 1
    i32.const 2
    array.new_fixed $arr_i32 2
    i32.const 3
    array.new_fixed $arr_i32 1
    array.new_fixed $arr_any 2
    call $__arr_flatten_i32
    call $__pr0
    call $__print_nl
    local.get $xs
    i32.const 2
    call $__arr_chunked_i32
    call $__pr4
    call $__print_nl
    local.get $xs
    i32.const 3
    call $__arr_sliding_i32
    call $__pr4
    call $__print_nl
    local.get $xs
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_i32
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_i32
        local.set $x
    local.get $__out0
    local.get $__idx0
    local.get $x
    i32.const 2
    global.get $__s5
    call $__i32_mul_chk
    array.set $arr_i32
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    call $__pr0
    call $__print_nl
    local.get $xs
    local.set $__iter1
    local.get $__iter1
    array.len
    local.set $__len1
    i32.const 0
    local.set $__idx1
    local.get $__len1
    array.new_default $arr_i32
    local.set $__out1
    i32.const 0
    local.set $__acc1
    (block $__break
      (loop $__continue
        local.get $__idx1
        local.get $__len1
        i32.ge_s
        br_if $__break
        local.get $__iter1
        local.get $__idx1
        array.get $arr_i32
        local.set $x
    local.get $x
    i32.const 1
    i32.gt_s
    (if
      (then
    local.get $__out1
    local.get $__acc1
    local.get $__iter1
    local.get $__idx1
    array.get $arr_i32
    array.set $arr_i32
    local.get $__acc1
    i32.const 1
    i32.add
    local.set $__acc1
      )
    )
        local.get $__idx1
        i32.const 1
        i32.add
        local.set $__idx1
        br $__continue
      )
    )
    local.get $__out1
    i32.const 0
    local.get $__acc1
    call $__arr_slice_i32
    call $__pr0
    call $__print_nl
    local.get $xs
    local.set $__iter2
    local.get $__iter2
    array.len
    local.set $__len2
    i32.const 0
    local.set $__idx2
    i32.const 0
    local.set $__acc2
    (block $__break
      (loop $__continue
        local.get $__idx2
        local.get $__len2
        i32.ge_s
        br_if $__break
        local.get $__iter2
        local.get $__idx2
        array.get $arr_i32
        local.set $x
        local.get $__acc2
        local.set $acc
    local.get $acc
    local.get $x
    global.get $__s6
    call $__i32_add_chk
    local.set $__acc2
        local.get $__idx2
        i32.const 1
        i32.add
        local.set $__idx2
        br $__continue
      )
    )
    local.get $__acc2
    call $__print_i32
    local.get $xs
    local.set $__iter3
    local.get $__iter3
    array.len
    local.set $__len3
    i32.const 0
    local.set $__idx3
    i32.const 0
    local.set $__acc3
    (block $__break
      (loop $__continue
        local.get $__idx3
        local.get $__len3
        i32.ge_s
        br_if $__break
        local.get $__iter3
        local.get $__idx3
        array.get $arr_i32
        local.set $x
    local.get $x
    i32.const 2
    i32.eq
    (if
      (then
    i32.const 1
    local.set $__acc3
      )
    )
        local.get $__idx3
        i32.const 1
        i32.add
        local.set $__idx3
        br $__continue
      )
    )
    local.get $__acc3
    call $__print_bool_raw
    call $__print_sp
    local.get $xs
    local.set $__iter4
    local.get $__iter4
    array.len
    local.set $__len4
    i32.const 0
    local.set $__idx4
    i32.const 1
    local.set $__acc4
    (block $__break
      (loop $__continue
        local.get $__idx4
        local.get $__len4
        i32.ge_s
        br_if $__break
        local.get $__iter4
        local.get $__idx4
        array.get $arr_i32
        local.set $x
    local.get $x
    i32.const 0
    i32.gt_s
    i32.eqz
    (if
      (then
    i32.const 0
    local.set $__acc4
      )
    )
        local.get $__idx4
        i32.const 1
        i32.add
        local.set $__idx4
        br $__continue
      )
    )
    local.get $__acc4
    call $__print_bool_raw
    call $__print_sp
    local.get $xs
    local.set $__iter5
    local.get $__iter5
    array.len
    local.set $__len5
    i32.const 0
    local.set $__idx5
    i32.const 0
    local.set $__acc5
    (block $__break
      (loop $__continue
        local.get $__idx5
        local.get $__len5
        i32.ge_s
        br_if $__break
        local.get $__iter5
        local.get $__idx5
        array.get $arr_i32
        local.set $x
    local.get $x
    i32.const 3
    i32.eq
    (if
      (then
    local.get $__acc5
    i32.const 1
    i32.add
    local.set $__acc5
      )
    )
        local.get $__idx5
        i32.const 1
        i32.add
        local.set $__idx5
        br $__continue
      )
    )
    local.get $__acc5
    call $__print_i32
    global.get $__s3
    global.get $__s7
    array.new_fixed $arr_any 2
    local.set $__iter6
    local.get $__iter6
    array.len
    local.set $__len6
    i32.const 0
    local.set $__idx6
    local.get $__len6
    array.new_default $arr_i32
    local.set $__out6
    i32.const 0
    local.set $__acc6
    (block $__break
      (loop $__continue
        local.get $__idx6
        local.get $__len6
        i32.ge_s
        br_if $__break
        local.get $__iter6
        local.get $__idx6
        array.get $arr_any
    ref.cast (ref null $str)
        local.set $s
    local.get $__out6
    local.get $__idx6
    local.get $s
    call $__std_text_length
    array.set $arr_i32
        local.get $__idx6
        i32.const 1
        i32.add
        local.set $__idx6
        br $__continue
      )
    )
    local.get $__out6
    call $__pr0
    call $__print_nl
    local.get $xs
    global.get $__s3
    global.get $__s4
    array.new_fixed $arr_any 2
    call $__arr_zip_i32_any
    call $__pr5
    call $__print_nl
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__pr1 (param $v i32)
    local.get $v
    call $__print_i32_raw
  )
  (func $__pr0 (param $v (ref null $arr_i32))
    (local $n i32)
    (local $i i32)
    global.get $__s0
    call $__print_str_raw
    local.get $v
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    global.get $__s1
    call $__print_str_raw
      )
    )
    local.get $v
    local.get $i
    array.get $arr_i32
    call $__pr1
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    global.get $__s2
    call $__print_str_raw
  )
  (func $__arr_slice_i32 (param $xs (ref null $arr_i32)) (param $a i32) (param $b i32) (result (ref null $arr_i32))
    (local $len i32)
    (local $from i32)
    (local $to i32)
    (local $n i32)
    (local $r (ref null $arr_i32))
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
    array.new_default $arr_i32
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    local.get $from
    local.get $n
    array.copy $arr_i32 $arr_i32
    local.get $r
  )
  (func $__arr_unique_i32 (param $xs (ref null $arr_i32)) (result (ref null $arr_i32))
    (local $n i32)
    (local $i i32)
    (local $j i32)
    (local $k i32)
    (local $x i32)
    (local $y i32)
    (local $out (ref null $arr_i32))
    local.get $xs
    array.len
    local.set $n
    local.get $n
    array.new_default $arr_i32
    local.set $out
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $xs
    local.get $i
    array.get $arr_i32
    local.set $x
    i32.const 0
    local.set $j
    (block $found
    (block $miss
    (loop $scan
    local.get $j
    local.get $k
    i32.ge_u
    br_if $miss
    local.get $out
    local.get $j
    array.get $arr_i32
    local.get $x
    i32.eq
    br_if $found
    local.get $j
    i32.const 1
    i32.add
    local.set $j
    br $scan
    )
    )
    local.get $out
    local.get $k
    local.get $x
    array.set $arr_i32
    local.get $k
    i32.const 1
    i32.add
    local.set $k
    )
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $out
    i32.const 0
    local.get $k
    call $__arr_slice_i32
  )
  (func $__pr3 (param $v (ref null $str))
    local.get $v
    call $__print_quoted_raw
  )
  (func $__pr2 (param $v (ref null $arr_any))
    (local $n i32)
    (local $i i32)
    global.get $__s0
    call $__print_str_raw
    local.get $v
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    global.get $__s1
    call $__print_str_raw
      )
    )
    local.get $v
    local.get $i
    array.get $arr_any
    ref.cast (ref null $str)
    call $__pr3
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    global.get $__s2
    call $__print_str_raw
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
  (func $__arr_unique_any (param $xs (ref null $arr_any)) (result (ref null $arr_any))
    (local $n i32)
    (local $i i32)
    (local $j i32)
    (local $k i32)
    (local $x anyref)
    (local $y (ref null $str))
    (local $out (ref null $arr_any))
    local.get $xs
    array.len
    local.set $n
    local.get $n
    array.new_default $arr_any
    local.set $out
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $xs
    local.get $i
    array.get $arr_any
    local.set $x
    i32.const 0
    local.set $j
    (block $found
    (block $miss
    (loop $scan
    local.get $j
    local.get $k
    i32.ge_u
    br_if $miss
    local.get $out
    local.get $j
    array.get $arr_any
    local.get $x
    ref.cast (ref null $str)
    local.set $y
    ref.cast (ref null $str)
    local.get $y
    call $__str_eq
    br_if $found
    local.get $j
    i32.const 1
    i32.add
    local.set $j
    br $scan
    )
    )
    local.get $out
    local.get $k
    local.get $x
    array.set $arr_any
    local.get $k
    i32.const 1
    i32.add
    local.set $k
    )
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $out
    i32.const 0
    local.get $k
    call $__arr_slice_any
  )
  (func $__arr_flatten_i32 (param $xs (ref null $arr_any)) (result (ref null $arr_i32))
    (local $n i32)
    (local $i i32)
    (local $t i32)
    (local $o i32)
    (local $a (ref null $arr_i32))
    (local $r (ref null $arr_i32))
    local.get $xs
    array.len
    local.set $n
    i32.const 0
    local.set $i
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $xs
    local.get $i
    array.get $arr_any
    ref.cast (ref null $arr_i32)
    local.set $a
    local.get $t
    local.get $a
    array.len
    i32.add
    local.set $t
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $t
    array.new_default $arr_i32
    local.set $r
    i32.const 0
    local.set $i
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $xs
    local.get $i
    array.get $arr_any
    ref.cast (ref null $arr_i32)
    local.set $a
    local.get $r
    local.get $o
    local.get $a
    i32.const 0
    local.get $a
    array.len
    array.copy $arr_i32 $arr_i32
    local.get $o
    local.get $a
    array.len
    i32.add
    local.set $o
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $r
  )
  (func $__pr4 (param $v (ref null $arr_any))
    (local $n i32)
    (local $i i32)
    global.get $__s0
    call $__print_str_raw
    local.get $v
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    global.get $__s1
    call $__print_str_raw
      )
    )
    local.get $v
    local.get $i
    array.get $arr_any
    ref.cast (ref null $arr_i32)
    call $__pr0
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    global.get $__s2
    call $__print_str_raw
  )
  (func $__arr_chunked_i32 (param $xs (ref null $arr_i32)) (param $m i32) (result (ref null $arr_any))
    (local $n i32)
    (local $cnt i32)
    (local $k i32)
    (local $from i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $n
    local.get $m
    i32.const 0
    i32.gt_s
    (if
      (then
    local.get $n
    local.get $m
    i32.div_u
    local.get $n
    local.get $m
    i32.rem_u
    i32.const 0
    i32.ne
    i32.add
    local.set $cnt
      )
    )
    local.get $cnt
    array.new_default $arr_any
    local.set $r
    (block $brk
    (loop $cont
    local.get $k
    local.get $cnt
    i32.ge_u
    br_if $brk
    local.get $k
    local.get $m
    i32.mul
    local.set $from
    local.get $r
    local.get $k
    local.get $xs
    local.get $from
    local.get $from
    local.get $m
    i32.add
    call $__arr_slice_i32
    array.set $arr_any
    local.get $k
    i32.const 1
    i32.add
    local.set $k
    br $cont
    )
    )
    local.get $r
  )
  (func $__arr_sliding_i32 (param $xs (ref null $arr_i32)) (param $m i32) (result (ref null $arr_any))
    (local $n i32)
    (local $cnt i32)
    (local $k i32)
    (local $from i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $n
    local.get $m
    i32.const 0
    i32.gt_s
    (if
      (then
    local.get $n
    local.get $m
    i32.sub
    i32.const 1
    i32.add
    local.set $cnt
    local.get $cnt
    i32.const 0
    i32.lt_s
    (if
      (then
    i32.const 0
    local.set $cnt
      )
    )
      )
    )
    local.get $cnt
    array.new_default $arr_any
    local.set $r
    (block $brk
    (loop $cont
    local.get $k
    local.get $cnt
    i32.ge_u
    br_if $brk
    local.get $k
    local.set $from
    local.get $r
    local.get $k
    local.get $xs
    local.get $from
    local.get $from
    local.get $m
    i32.add
    call $__arr_slice_i32
    array.set $arr_any
    local.get $k
    i32.const 1
    i32.add
    local.set $k
    br $cont
    )
    )
    local.get $r
  )
  (func $__pr6 (param $v (ref null $arr_any))
    global.get $__s8
    call $__print_str_raw
    local.get $v
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__pr1
    global.get $__s1
    call $__print_str_raw
    local.get $v
    i32.const 1
    array.get $arr_any
    ref.cast (ref null $str)
    call $__pr3
    global.get $__s9
    call $__print_str_raw
  )
  (func $__pr5 (param $v (ref null $arr_any))
    (local $n i32)
    (local $i i32)
    global.get $__s0
    call $__print_str_raw
    local.get $v
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    global.get $__s1
    call $__print_str_raw
      )
    )
    local.get $v
    local.get $i
    array.get $arr_any
    ref.cast (ref null $arr_any)
    call $__pr6
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    global.get $__s2
    call $__print_str_raw
  )
  (func $__arr_zip_i32_any (param $xs (ref null $arr_i32)) (param $ys (ref null $arr_any)) (result (ref null $arr_any))
    (local $n i32)
    (local $i i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $n
    local.get $ys
    array.len
    local.get $n
    i32.lt_u
    (if
      (then
    local.get $ys
    array.len
    local.set $n
      )
    )
    local.get $n
    array.new_default $arr_any
    local.set $r
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $r
    local.get $i
    local.get $xs
    local.get $i
    array.get $arr_i32
    struct.new $box_i32
    local.get $ys
    local.get $i
    array.get $arr_any
    array.new_fixed $tuple 2
    array.set $arr_any
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $r
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
  (func $__print_nl
    i32.const 8
    i32.const 10
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  ;; separator between the arguments of a multi-argument `@print`
  (func $__print_sp
    i32.const 8
    i32.const 32
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i32 (param $n i32)
    local.get $n
    call $__print_i32_raw
    call $__print_nl
  )
  (func $__print_i32_raw (param $n i32)
    (local $buf i32) (local $len i32) (local $neg i32) (local $d i32)
    (local $i i32) (local $j i32) (local $tmp i32)
    i32.const 64
    local.set $buf
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 1
        local.set $neg
        i32.const 0
        local.get $n
        i32.sub
        local.set $n
      )
    )
    (block $done
      (loop $digits
        local.get $n
        i32.const 10
        i32.rem_u
        i32.const 48
        i32.add
        local.set $d
        local.get $buf
        local.get $len
        i32.add
        local.get $d
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
        local.get $n
        i32.const 10
        i32.div_u
        local.set $n
        local.get $n
        i32.const 0
        i32.gt_u
        br_if $digits
      )
    )
    ;; reverse
    i32.const 0
    local.set $i
    local.get $len
    i32.const 1
    i32.sub
    local.set $j
    (block $rdone
      (loop $rev
        local.get $i
        local.get $j
        i32.ge_u
        br_if $rdone
        local.get $buf
        local.get $i
        i32.add
        i32.load8_u
        local.set $tmp
        local.get $buf
        local.get $i
        i32.add
        local.get $buf
        local.get $j
        i32.add
        i32.load8_u
        i32.store8
        local.get $buf
        local.get $j
        i32.add
        local.get $tmp
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        local.get $j
        i32.const 1
        i32.sub
        local.set $j
        br $rev
      )
    )
    ;; add neg sign + newline
    ;; shift the digits one byte right to make room for '-'
    ;; (dst = buf+1, NOT buf+len: the latter moved them `len`
    ;;  bytes and printed -12 as -21)
    local.get $neg
    (if
      (then
        local.get $buf
        i32.const 1
        i32.add
        local.get $buf
        local.get $len
        call $__memmove
        local.get $buf
        i32.const 45
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
      )
    )
    local.get $buf
    local.get $len
    call $__write_bytes
  )
  (func $__memmove (param $dst i32) (param $src i32) (param $len i32)
    (local $i i32)
    local.get $len
    i32.const 1
    i32.sub
    local.set $i
    (block $done
      (loop $loop
        local.get $i
        i32.const 0
        i32.lt_s
        br_if $done
        local.get $dst
        local.get $i
        i32.add
        local.get $src
        local.get $i
        i32.add
        i32.load8_u
        i32.store8
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        br $loop
      )
    )
  )
  (func $__print_str_raw (param $s (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    local.get $s
    array.len
    local.set $n
    global.get $__heap_ptr
    local.set $top
    local.get $n
    call $__alloc
    local.set $p
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $s
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
    local.get $n
    call $__write_bytes
    local.get $top
    global.set $__heap_ptr
  )
  (func $__print_str (param $s (ref null $str))
    local.get $s
    call $__print_str_raw
    call $__print_nl
  )
  (func $__print_bool (param $b i32)
    local.get $b
    call $__print_bool_raw
    call $__print_nl
  )
  (func $__print_bool_raw (param $b i32)
    local.get $b
    (if
      (then
        ;; "true" as a little-endian i32
        i32.const 16
        i32.const 1702195828
        i32.store
        i32.const 16
        i32.const 4
        call $__write_bytes
      )
      (else
        ;; "fals" + 'e'
        i32.const 16
        i32.const 1936482662
        i32.store
        i32.const 16
        i32.const 101
        i32.store8 offset=4
        i32.const 16
        i32.const 5
        call $__write_bytes
      )
    )
  )
  (func $__print_f64 (param $x f64)
    local.get $x
    call $__print_f64_raw
    call $__print_nl
  )
  (func $__print_f64_raw (param $x f64)
    (local $s i32) (local $top i32)
    global.get $__heap_ptr
    local.set $top
    local.get $x
    call $__std_number_floatToString
    local.set $s
    local.get $s
    i32.const 4
    i32.add
    local.get $s
    i32.load
    call $__write_bytes
    local.get $top
    global.set $__heap_ptr
  )
  (func $__str_eq (param $a (ref null $str)) (param $b (ref null $str)) (result i32)
    (local $i i32) (local $n i32) (local $an i32) (local $bn i32)
    local.get $a
    ref.is_null
    local.set $an
    local.get $b
    ref.is_null
    local.set $bn
    local.get $an
    local.get $bn
    i32.or
    (if
      (then
        local.get $an
        local.get $bn
        i32.and
        return
      )
    )
    local.get $a
    array.len
    local.set $n
    local.get $n
    local.get $b
    array.len
    i32.ne
    (if
      (then
        i32.const 0
        return
      )
    )
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $a
        local.get $i
        array.get_u $str
        local.get $b
        local.get $i
        array.get_u $str
        i32.ne
        (if
          (then
            i32.const 0
            return
          )
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
  (func $__write_err (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 2
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__assert_fail (param $where i32) (param $msg i32)
    local.get $where
    i32.const 4
    i32.add
    local.get $where
    i32.load
    call $__write_err
    i32.const 188
    i64.const 8390880602276044858
    i64.store
    i32.const 196
    i64.const 7811882119909502825
    i64.store
    i32.const 204
    i32.const 101
    i32.store8
    i32.const 205
    i32.const 100
    i32.store8
    i32.const 188
    i32.const 18
    call $__write_err
    local.get $msg
    (if
      (then
        i32.const 188
        i32.const 8250
        i32.store
        i32.const 188
        i32.const 2
        call $__write_err
        local.get $msg
        i32.const 4
        i32.add
        local.get $msg
        i32.load
        call $__write_err
      )
    )
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
  )
  (func $__panic_fail (param $msg (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    i32.const 188
    i64.const 9071397899755888
    i64.store
    i32.const 188
    i32.const 7
    call $__write_err
    local.get $msg
    array.len
    local.set $n
    global.get $__heap_ptr
    local.set $top
    local.get $n
    call $__alloc
    local.set $p
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $msg
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
    local.get $n
    call $__write_err
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
    local.get $top
    global.set $__heap_ptr
  )
  (func $__print_quoted_raw (param $s (ref null $str))
    (local $n i32) (local $i i32) (local $ch i32) (local $e i32)
    i32.const 8
    i32.const 34
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
    local.get $s
    array.len
    local.set $n
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $s
        local.get $i
        array.get_u $str
        local.set $ch
        i32.const 0
        local.set $e
        local.get $ch
        i32.const 34
        i32.eq
        local.get $ch
        i32.const 92
        i32.eq
        i32.or
        (if
          (then
            local.get $ch
            local.set $e
          )
        )
        local.get $ch
        i32.const 10
        i32.eq
        (if
          (then
            i32.const 110
            local.set $e
          )
        )
        local.get $ch
        i32.const 13
        i32.eq
        (if
          (then
            i32.const 114
            local.set $e
          )
        )
        local.get $ch
        i32.const 9
        i32.eq
        (if
          (then
            i32.const 116
            local.set $e
          )
        )
        local.get $e
        (if
          (then
            i32.const 8
            i32.const 92
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
            i32.const 8
            local.get $e
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
          )
          (else
            i32.const 8
            local.get $ch
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    i32.const 8
    i32.const 34
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i64_raw (param $v i64)
    local.get $v
    call $__std_number_i64ToString
    call $__print_str_raw
  )
  (func $__print_i64 (param $v i64)
    local.get $v
    call $__print_i64_raw
    call $__print_nl
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.add
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.sub
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.mul
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.add
    local.set $r
    local.get $a
    local.get $r
    i64.xor
    local.get $b
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.sub
    local.set $r
    local.get $a
    local.get $b
    i64.xor
    local.get $a
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
    (local $r i64)
    local.get $a
    i64.const -1
    i64.eq
    local.get $b
    i64.const -9223372036854775808
    i64.eq
    i32.and
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    local.get $b
    i64.mul
    local.set $r
    local.get $a
    i64.eqz
    i32.eqz
    (if
      (then
        local.get $r
        local.get $a
        i64.div_s
        local.get $b
        i64.ne
        (if
          (then
            local.get $site
            call $__chk_fail
            unreachable
          )
        )
      )
    )
    local.get $r
  )
  (func $__print_u64_raw (param $v i64)
    local.get $v
    call $__std_number_u64ToString
    call $__print_str_raw
  )
  (func $__print_u64 (param $v i64)
    local.get $v
    call $__print_u64_raw
    call $__print_nl
  )
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  (func $__std_text_length (param $p0 (ref null $str)) (result i32)
    local.get $p0
    call $__abi___std_text_length
  )
  (func $__std_number_i64ToString (param $p0 i64) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_i64ToString
    ref.cast (ref null $str)
  )
  (func $__std_number_u64ToString (param $p0 i64) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_u64ToString
    ref.cast (ref null $str)
  )
  (data $__d0 "[")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 ", ")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "]")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "a")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "b")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "integer overflow: * on i32 at main.bp:8:27")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "integer overflow: + on i32 at main.bp:10:38")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "bb")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "#(")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 ")")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 1
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 2
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 1
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 1
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 1
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 42
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 43
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 2
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 2
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 1
    array.new_data $str $__d9
    global.set $__s9
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
[3, 1, 2]
["a", "b"]
[1, 2, 3]
[[3, 1], [3, 2], [1]]
[[3, 1, 3], [1, 3, 2], [3, 2, 1]]
[6, 2, 6, 4, 2]
[3, 3, 2]
10
true true 2
[1, 2]
[#(3, "a"), #(1, "b")]
```
