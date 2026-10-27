----- SOURCE CODE -- main.bp
```botopink
type Pair(a: i32, b: string)

pub fn main() -> void {
    val t = #(1, "x", 2.5, true);
    print(t);
    print(t.0);
    print(t.1);
    print(t._2);
    print(t._3);
    val u = #(1, "x", 2.5, true);
    print(t == u);
    val rs = [Pair(a: 1, b: "p"), Pair(a: 2, b: "q")];
    print(rs);
    for (rs) { r -> print(r.b); }
    val ts = [#(1, "a"), #(2, "b")];
    print(ts);
    print(ts[0]);
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
    (type $rec_Pair (struct (field $f0 (mut i32)) (field $f1 (mut (ref null $str)))))
    (type $brand_rec_Pair (struct (field f32) (field f32) (field i32) (field f32) (field f32) (field f64) (field f64) (field f64) (field f64) (field i32) (field f32) (field i32) (field f32) (field f32) (field f64) (field f64) (field i32) (field f64) (field f64) (field f32) (field f64) (field f64) (field f64) (field i64) (field i32) (field i32) (field i32) (field i64) (field i32) (field f64) (field f64) (field i64)))
  )
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@number" "wat:number.i64ToString" (func $__std_number_i64ToString (param i64) (result (ref null $str))))
  (import "std@number" "wat:number.u64ToString" (func $__std_number_u64ToString (param i64) (result (ref null $str))))
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
    (local $__mem7 i32)
    (local $t (ref null $arr_any))
    (local $u (ref null $arr_any))
    (local $rs (ref null $arr_any))
    (local $r i32)
    (local $ts (ref null $arr_any))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $r__sh0 (ref null $rec_Pair))
    (local $__gc0 (ref null $arr_any))
    i32.const 1
    struct.new $box_i32
    global.get $__s0
    f64.const 2.5
    struct.new $box_f64
    i32.const 1
    struct.new $box_i32
    array.new_fixed $tuple 4
    local.set $t
    local.get $t
    call $__pr0
    call $__print_nl
    local.get $t
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32
    local.get $t
    i32.const 1
    array.get $arr_any
    ref.cast (ref null $str)
    call $__print_str
    local.get $t
    i32.const 2
    array.get $arr_any
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    call $__print_f64
    local.get $t
    i32.const 3
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_bool
    i32.const 1
    struct.new $box_i32
    global.get $__s0
    f64.const 2.5
    struct.new $box_f64
    i32.const 1
    struct.new $box_i32
    array.new_fixed $tuple 4
    local.set $u
    local.get $t
    local.get $u
    call $__eq_Tuple4_i32_string_f64_bool
    call $__print_bool
    i32.const 1
    global.get $__s4
    struct.new $rec_Pair
    i32.const 2
    global.get $__s5
    struct.new $rec_Pair
    array.new_fixed $arr_any 2
    local.set $rs
    local.get $rs
    call $__pr5
    call $__print_nl
    local.get $rs
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $rec_Pair)
        local.set $r__sh0
    local.get $r__sh0
    struct.get $rec_Pair $f1
    call $__print_str
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    i32.const 0
    drop
    i32.const 1
    struct.new $box_i32
    global.get $__s8
    array.new_fixed $tuple 2
    i32.const 2
    struct.new $box_i32
    global.get $__s9
    array.new_fixed $tuple 2
    array.new_fixed $arr_any 2
    local.set $ts
    local.get $ts
    call $__pr7
    call $__print_nl
    local.get $ts
    i32.const 0
    call $__arr_at_opt_any
    ref.cast (ref null $arr_any)
    local.tee $__gc0
    ref.is_null
    (if
      (then
    global.get $__s10
    call $__print_str_raw
      )
      (else
    local.get $__gc0
    call $__pr8
      )
    )
    call $__print_nl
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__eq_Tuple4_i32_string_f64_bool (param $a (ref null $arr_any)) (param $b (ref null $arr_any)) (result i32)
    local.get $a
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.get $b
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    i32.const 1
    array.get $arr_any
    ref.cast (ref null $str)
    local.get $b
    i32.const 1
    array.get $arr_any
    ref.cast (ref null $str)
    call $__str_eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    i32.const 2
    array.get $arr_any
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    local.get $b
    i32.const 2
    array.get $arr_any
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    call $__f64_eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    i32.const 3
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.get $b
    i32.const 3
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    i32.const 1
  )
  (func $__f64_eq (param $a f64) (param $b f64) (result i32)
    local.get $a
    local.get $a
    f64.ne
    local.get $b
    local.get $b
    f64.ne
    i32.and ;; both NaN
    local.get $a
    i64.reinterpret_f64
    local.get $b
    i64.reinterpret_f64
    i64.eq ;; the same bits
    i32.or
  )
  (func $__pr1 (param $v i32)
    local.get $v
    call $__print_i32_raw
  )
  (func $__pr2 (param $v (ref null $str))
    local.get $v
    call $__print_quoted_raw
  )
  (func $__pr3 (param $v f64)
    local.get $v
    call $__print_f64_raw
  )
  (func $__pr4 (param $v i32)
    local.get $v
    call $__print_bool_raw
  )
  (func $__pr0 (param $v (ref null $arr_any))
    global.get $__s1
    call $__print_str_raw
    local.get $v
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__pr1
    global.get $__s2
    call $__print_str_raw
    local.get $v
    i32.const 1
    array.get $arr_any
    ref.cast (ref null $str)
    call $__pr2
    global.get $__s2
    call $__print_str_raw
    local.get $v
    i32.const 2
    array.get $arr_any
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    call $__pr3
    global.get $__s2
    call $__print_str_raw
    local.get $v
    i32.const 3
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__pr4
    global.get $__s3
    call $__print_str_raw
  )
  (func $__pr6 (param $v anyref)
    local.get $v
    call $__print_tagged_raw
  )
  (func $__pr5 (param $v (ref null $arr_any))
    (local $n i32)
    (local $i i32)
    global.get $__s6
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
    global.get $__s2
    call $__print_str_raw
      )
    )
    local.get $v
    local.get $i
    array.get $arr_any
    call $__pr6
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    global.get $__s7
    call $__print_str_raw
  )
  (func $__pr8 (param $v (ref null $arr_any))
    global.get $__s1
    call $__print_str_raw
    local.get $v
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__pr1
    global.get $__s2
    call $__print_str_raw
    local.get $v
    i32.const 1
    array.get $arr_any
    ref.cast (ref null $str)
    call $__pr2
    global.get $__s3
    call $__print_str_raw
  )
  (func $__pr7 (param $v (ref null $arr_any))
    (local $n i32)
    (local $i i32)
    global.get $__s6
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
    global.get $__s2
    call $__print_str_raw
      )
    )
    local.get $v
    local.get $i
    array.get $arr_any
    ref.cast (ref null $arr_any)
    call $__pr8
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    global.get $__s7
    call $__print_str_raw
  )
  (func $__arr_at_opt_any (param $xs (ref null $arr_any)) (param $i i32) (result anyref)
    local.get $i
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $i
    local.get $xs
    array.len
    i32.add
    local.set $i
      )
    )
    local.get $i
    i32.const 0
    i32.lt_s
    local.get $i
    local.get $xs
    array.len
    i32.ge_s
    i32.or
    (if (result anyref)
      (then
    ref.null any
      )
      (else
    local.get $xs
    local.get $i
    array.get $arr_any
      )
    )
  )
  (func $__pr9 (param $v (ref null $rec_Pair))
    global.get $__s11
    call $__print_str_raw
    global.get $__s12
    call $__print_str_raw
    global.get $__s13
    call $__print_str_raw
    local.get $v
    struct.get $rec_Pair $f0
    call $__pr1
    global.get $__s14
    call $__print_str_raw
    local.get $v
    struct.get $rec_Pair $f1
    call $__pr2
    global.get $__s3
    call $__print_str_raw
  )
  (func $__print_tagged_raw (param $v anyref)
    local.get $v
    ref.test (ref null $rec_Pair)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Pair)
    call $__pr9
    return
      )
    )
    unreachable
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
  (func $__write_bytes (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
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
  (data $__d0 "x")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "#(")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 ", ")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 ")")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "p")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "q")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "[")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "]")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "a")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "b")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "null")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 "Pair")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (data $__d12 "(")
  (global $__s12 (mut (ref null $str)) (ref.null $str))
  (data $__d13 "a: ")
  (global $__s13 (mut (ref null $str)) (ref.null $str))
  (data $__d14 ", b: ")
  (global $__s14 (mut (ref null $str)) (ref.null $str))
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
    i32.const 2
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
    i32.const 1
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 1
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 1
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 1
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 1
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 4
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 4
    array.new_data $str $__d11
    global.set $__s11
    i32.const 0
    i32.const 1
    array.new_data $str $__d12
    global.set $__s12
    i32.const 0
    i32.const 3
    array.new_data $str $__d13
    global.set $__s13
    i32.const 0
    i32.const 5
    array.new_data $str $__d14
    global.set $__s14
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
#(1, "x", 2.5, true)
1
x
2.5
true
true
[Pair(a: 1, b: "p"), Pair(a: 2, b: "q")]
p
q
[#(1, "a"), #(2, "b")]
#(1, "a")
```
