----- SOURCE CODE -- main.bp
```botopink
fn main() -> void {
    val a = #(1, "a");
    val b = #(1, "a");
    print(a == b);
    print(a != b);
    val c = #(1, "b");
    print(a == c);
    val name = "SP";
    val pop = 12;
    val labeled = #(name, pop);
    val plain = #("SP", 12);
    print(labeled == plain);
    val n1 = #(#(1, 2), "x");
    val n2 = #(#(1, 2), "x");
    val n3 = #(#(1, 3), "x");
    print(n1 == n2);
    print(n1 == n3);
    val f1 = #(1.5, true);
    val f2 = #(1.5, true);
    val f3 = #(1.5, false);
    print(f1 == f2);
    print(f1 == f3);
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
    (type $sig_0 (func (param (ref null $closure)) (result anyref)))
    (type $sig_1 (func (param (ref null $closure) anyref) (result anyref)))
    (type $sig_2 (func (param (ref null $closure) anyref anyref) (result anyref)))
    (type $sig_3 (func (param (ref null $closure) anyref anyref anyref) (result anyref)))
    (type $sig_4 (func (param (ref null $closure) anyref anyref anyref anyref) (result anyref)))
    (type $sig_5 (func (param (ref null $closure) anyref anyref anyref anyref anyref) (result anyref)))
    (type $sig_6 (func (param (ref null $closure) anyref anyref anyref anyref anyref anyref) (result anyref)))
    (type $sig_7 (func (param (ref null $closure) anyref anyref anyref anyref anyref anyref anyref) (result anyref)))
    (type $sig_8 (func (param (ref null $closure) anyref anyref anyref anyref anyref anyref anyref anyref) (result anyref)))
  )
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $main
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    (local $__mem5 i32)
    (local $__mem6 i32)
    (local $__mem7 i32)
    (local $__mem8 i32)
    (local $__mem9 i32)
    (local $__mem10 i32)
    (local $__mem11 i32)
    (local $__mem12 i32)
    (local $__mem13 i32)
    (local $a (ref null $arr_any))
    (local $b (ref null $arr_any))
    (local $c (ref null $arr_any))
    (local $name (ref null $str))
    (local $pop i32)
    (local $labeled (ref null $arr_any))
    (local $plain (ref null $arr_any))
    (local $n1 (ref null $arr_any))
    (local $n2 (ref null $arr_any))
    (local $n3 (ref null $arr_any))
    (local $f1 (ref null $arr_any))
    (local $f2 (ref null $arr_any))
    (local $f3 (ref null $arr_any))
    i32.const 1
    struct.new $box_i32
    global.get $__s0
    array.new_fixed $tuple 2
    local.set $a
    i32.const 1
    struct.new $box_i32
    global.get $__s0
    array.new_fixed $tuple 2
    local.set $b
    local.get $a
    local.get $b
    call $__eq_Tuple2_i32_string
    call $__print_bool
    local.get $a
    local.get $b
    call $__eq_Tuple2_i32_string
    i32.eqz
    call $__print_bool
    i32.const 1
    struct.new $box_i32
    global.get $__s1
    array.new_fixed $tuple 2
    local.set $c
    local.get $a
    local.get $c
    call $__eq_Tuple2_i32_string
    call $__print_bool
    global.get $__s2
    local.set $name
    i32.const 12
    local.set $pop
    local.get $name
    local.get $pop
    struct.new $box_i32
    array.new_fixed $tuple 2
    local.set $labeled
    global.get $__s2
    i32.const 12
    struct.new $box_i32
    array.new_fixed $tuple 2
    local.set $plain
    local.get $labeled
    local.get $plain
    call $__eq_Tuple2_string_i32
    call $__print_bool
    i32.const 1
    struct.new $box_i32
    i32.const 2
    struct.new $box_i32
    array.new_fixed $tuple 2
    global.get $__s3
    array.new_fixed $tuple 2
    local.set $n1
    i32.const 1
    struct.new $box_i32
    i32.const 2
    struct.new $box_i32
    array.new_fixed $tuple 2
    global.get $__s3
    array.new_fixed $tuple 2
    local.set $n2
    i32.const 1
    struct.new $box_i32
    i32.const 3
    struct.new $box_i32
    array.new_fixed $tuple 2
    global.get $__s3
    array.new_fixed $tuple 2
    local.set $n3
    local.get $n1
    local.get $n2
    call $__eq_Tuple2_Tuple2_i32_i32_string
    call $__print_bool
    local.get $n1
    local.get $n3
    call $__eq_Tuple2_Tuple2_i32_i32_string
    call $__print_bool
    f64.const 1.5
    struct.new $box_f64
    i32.const 1
    struct.new $box_i32
    array.new_fixed $tuple 2
    local.set $f1
    f64.const 1.5
    struct.new $box_f64
    i32.const 1
    struct.new $box_i32
    array.new_fixed $tuple 2
    local.set $f2
    f64.const 1.5
    struct.new $box_f64
    i32.const 0
    struct.new $box_i32
    array.new_fixed $tuple 2
    local.set $f3
    local.get $f1
    local.get $f2
    call $__eq_Tuple2_f64_bool
    call $__print_bool
    local.get $f1
    local.get $f3
    call $__eq_Tuple2_f64_bool
    call $__print_bool
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__eq_Tuple2_i32_string (param $a (ref null $arr_any)) (param $b (ref null $arr_any)) (result i32)
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
    i32.const 1
  )
  (func $__eq_Tuple2_string_i32 (param $a (ref null $arr_any)) (param $b (ref null $arr_any)) (result i32)
    local.get $a
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $str)
    local.get $b
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $str)
    call $__str_eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    i32.const 1
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.get $b
    i32.const 1
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
  (func $__eq_Tuple2_Tuple2_i32_i32_string (param $a (ref null $arr_any)) (param $b (ref null $arr_any)) (result i32)
    local.get $a
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $arr_any)
    local.get $b
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $arr_any)
    call $__eq_Tuple2_i32_i32
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
    i32.const 1
  )
  (func $__eq_Tuple2_f64_bool (param $a (ref null $arr_any)) (param $b (ref null $arr_any)) (result i32)
    local.get $a
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    local.get $b
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    call $__f64_eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    i32.const 1
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.get $b
    i32.const 1
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
  (func $__eq_Tuple2_i32_i32 (param $a (ref null $arr_any)) (param $b (ref null $arr_any)) (result i32)
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
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.get $b
    i32.const 1
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
  (data $__d0 "a")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "b")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "SP")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "x")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
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
    i32.const 2
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 1
    array.new_data $str $__d3
    global.set $__s3
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
true
false
false
true
true
false
true
false
```
