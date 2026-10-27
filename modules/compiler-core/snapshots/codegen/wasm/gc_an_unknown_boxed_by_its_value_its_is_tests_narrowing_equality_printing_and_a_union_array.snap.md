----- SOURCE CODE -- main.bp
```botopink
fn describe(x: unknown) -> string {
    return case x {
        i32 { n ->
            "number " + n.toString()
        }
        string { s ->
            "text " + s
        }
        _ {
            "other"
        }
    };
}

fn show(x: unknown) -> string {
    if (x is i32) return "i32";
    if (x is f64) return "f64";
    if (x is string) return "string";
    if (x is bool) return "bool";
    return "other";
}

pub fn main() -> void {
    print(describe(3));
    print(describe("a"));
    print(describe(true));
    print(show(1), show(2.5), show("s"), show(false));
    val two: unknown = 2.0;
    print(two == 2, two == 3);
    val t: unknown = "hi";
    print(t == "hi", t);
    val b: unknown = true;
    print(b);
    print(300 is i8, 100 is i8, 2 is f64);
    val xs = [1, "a", true];
    print(xs);
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
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@number" "wat:number.i32ToString" (func $__std_number_i32ToString (param i32) (result (ref null $str))))
  (import "std@number" "wat:number.i64ToString" (func $__std_number_i64ToString (param i64) (result (ref null $str))))
  (import "std@number" "wat:number.u64ToString" (func $__std_number_u64ToString (param i64) (result (ref null $str))))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $describe (param $x anyref) (result (ref null $str))
    (local $i32 i32)
    (local $string i32)
    (local $__case_0 anyref)
    (local $n i32)
    (local $__gc0 anyref)
    (local $s (ref null $str))
    local.get $x
    local.set $__case_0
    local.get $__case_0
    i32.const -2147483648
    i32.const 2147483647
    call $__unk_int_in
    (if (result (ref null $str))
      (then
    local.get $__case_0
    call $__unk_as_i32
    local.set $n
    global.get $__s0
    local.get $n
    call $__std_number_i32ToString
    call $__str_concat
      )
      (else
    local.get $__case_0
    local.tee $__gc0
    ref.test (ref null $str)
    local.get $__gc0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $str)
    local.set $s
    global.get $__s1
    local.get $s
    call $__str_concat
      )
      (else
    global.get $__s2
      )
    )
      )
    )
    return
  )
  (func $show (param $x anyref) (result (ref null $str))
    (local $x__is0 i32)
    (local $x__is1 f64)
    (local $__gc1 anyref)
    (local $x__is2 (ref null $str))
    (local $__gc2 anyref)
    (local $x__is3 i32)
    local.get $x
    i32.const -2147483648
    i32.const 2147483647
    call $__unk_int_in
    (if (result (ref null $str))
      (then
    local.get $x
    call $__unk_as_i32
    local.set $x__is0
    global.get $__s3
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    local.get $x
    call $__unk_is_num
    (if (result (ref null $str))
      (then
    local.get $x
    call $__unk_as_f64
    local.set $x__is1
    global.get $__s4
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    local.get $x
    local.tee $__gc1
    ref.test (ref null $str)
    local.get $__gc1
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $x
    ref.cast (ref null $str)
    local.set $x__is2
    global.get $__s5
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    local.get $x
    local.tee $__gc2
    ref.test (ref null $box_bool)
    local.get $__gc2
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $x
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $x__is3
    global.get $__s6
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    global.get $__s2
    return
  )
  (func $main (export "main")
    (local $__mem0 i32)
    (local $two anyref)
    (local $t anyref)
    (local $b anyref)
    (local $xs (ref null $arr_any))
    i32.const 3
    struct.new $box_i32
    call $describe
    call $__print_str
    global.get $__s7
    call $describe
    call $__print_str
    i32.const 1
    struct.new $box_bool
    call $describe
    call $__print_str
    i32.const 1
    struct.new $box_i32
    call $show
    call $__print_str_raw
    call $__print_sp
    f64.const 2.5
    struct.new $box_f64
    call $show
    call $__print_str_raw
    call $__print_sp
    global.get $__s8
    call $show
    call $__print_str_raw
    call $__print_sp
    i32.const 0
    struct.new $box_bool
    call $show
    call $__print_str
    f64.const 2.0
    struct.new $box_f64
    local.set $two
    local.get $two
    i32.const 2
    struct.new $box_i32
    call $__unk_eq
    call $__print_bool_raw
    call $__print_sp
    local.get $two
    i32.const 3
    struct.new $box_i32
    call $__unk_eq
    call $__print_bool
    global.get $__s9
    local.set $t
    local.get $t
    global.get $__s9
    call $__unk_eq
    call $__print_bool_raw
    call $__print_sp
    local.get $t
    call $__unk_print_raw
    call $__print_nl
    i32.const 1
    struct.new $box_bool
    local.set $b
    local.get $b
    call $__unk_print_raw
    call $__print_nl
    i32.const 300
    struct.new $box_i32
    i32.const -128
    i32.const 127
    call $__unk_int_in
    call $__print_bool_raw
    call $__print_sp
    i32.const 100
    struct.new $box_i32
    i32.const -128
    i32.const 127
    call $__unk_int_in
    call $__print_bool_raw
    call $__print_sp
    i32.const 2
    struct.new $box_i32
    call $__unk_is_num
    call $__print_bool
    i32.const 1
    struct.new $box_i32
    global.get $__s7
    i32.const 1
    struct.new $box_bool
    array.new_fixed $arr_any 3
    local.set $xs
    local.get $xs
    call $__pr0
    call $__print_nl
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__unk_int_in (param $v anyref) (param $lo i32) (param $hi i32) (result i32)
    (local $k i32)
    (local $x f64)
    local.get $v
    ref.is_null
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.test (ref null $box_bool)
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i32)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.tee $k
    local.get $lo
    i32.ge_s
    local.get $k
    local.get $hi
    i32.le_s
    i32.and
    return
      )
    )
    local.get $v
    ref.test (ref null $box_f64)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    local.tee $x
    f64.floor
    local.get $x
    f64.ne
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $x
    local.get $lo
    f64.convert_i32_s
    f64.ge
    local.get $x
    local.get $hi
    f64.convert_i32_s
    f64.le
    i32.and
  )
  (func $__unk_as_i32 (param $v anyref) (result i32)
    local.get $v
    ref.test (ref null $box_f64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    i32.trunc_f64_s
    return
      )
    )
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
  )
  (func $__unk_is_num (param $v anyref) (result i32)
    local.get $v
    ref.is_null
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i32)
    local.get $v
    ref.test (ref null $box_bool)
    i32.eqz
    i32.and
    local.get $v
    ref.test (ref null $box_f64)
    i32.or
  )
  (func $__unk_as_f64 (param $v anyref) (result f64)
    local.get $v
    ref.test (ref null $box_i32)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    f64.convert_i32_s
    return
      )
    )
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
  )
  (func $__unk_eq (param $a anyref) (param $b anyref) (result i32)
    local.get $a
    call $__unk_is_num
    local.get $b
    call $__unk_is_num
    i32.and
    (if
      (then
    local.get $a
    call $__unk_as_f64
    local.get $b
    call $__unk_as_f64
    f64.eq
    return
      )
    )
    local.get $a
    ref.test (ref null $str)
    local.get $a
    ref.is_null
    i32.eqz
    i32.and
    local.get $b
    ref.test (ref null $str)
    i32.and
    local.get $b
    ref.is_null
    i32.eqz
    i32.and
    (if
      (then
    local.get $a
    ref.cast (ref null $str)
    local.get $b
    ref.cast (ref null $str)
    call $__str_eq
    return
      )
    )
    local.get $a
    ref.test (ref null $box_bool)
    local.get $a
    ref.is_null
    i32.eqz
    i32.and
    local.get $b
    ref.test (ref null $box_bool)
    i32.and
    local.get $b
    ref.is_null
    i32.eqz
    i32.and
    (if
      (then
    local.get $a
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.get $b
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    i32.eq
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__unk_print_raw (param $v anyref)
    local.get $v
    ref.is_null
    (if
      (then
    global.get $__s10
    call $__print_str_raw
    return
      )
    )
    local.get $v
    call $__print_ebox
    (if
      (then
    return
      )
    )
    local.get $v
    call $__print_arrs
    (if
      (then
    return
      )
    )
    local.get $v
    ref.test (ref null $box_bool)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_bool)
    struct.get $box_bool $v
    call $__print_bool_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i32)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_f64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    call $__print_f64_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i64)
    struct.get $box_i64 $v
    call $__print_i64_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $str)
    (if
      (then
    local.get $v
    ref.cast (ref null $str)
    call $__print_str_raw
    return
      )
    )
    local.get $v
    call $__print_tagged_raw
  )
  (func $__unk_print_q (param $v anyref)
    local.get $v
    ref.is_null
    (if
      (then
    global.get $__s10
    call $__print_str_raw
    return
      )
    )
    local.get $v
    call $__print_ebox
    (if
      (then
    return
      )
    )
    local.get $v
    call $__print_arrs
    (if
      (then
    return
      )
    )
    local.get $v
    ref.test (ref null $box_bool)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_bool)
    struct.get $box_bool $v
    call $__print_bool_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i32)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_f64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    call $__print_f64_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i64)
    struct.get $box_i64 $v
    call $__print_i64_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $str)
    (if
      (then
    local.get $v
    ref.cast (ref null $str)
    call $__print_quoted_raw
    return
      )
    )
    local.get $v
    call $__print_tagged_raw
  )
  (func $__pr1 (param $v anyref)
    local.get $v
    call $__unk_print_q
  )
  (func $__pr0 (param $v (ref null $arr_any))
    (local $n i32)
    (local $i i32)
    global.get $__s11
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
    global.get $__s12
    call $__print_str_raw
      )
    )
    local.get $v
    local.get $i
    array.get $arr_any
    call $__pr1
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    global.get $__s13
    call $__print_str_raw
  )
  (func $__unk_eq_s4 (param $a (ref null $box_i64)) (param $b (ref null $box_i64)) (result i32)
    local.get $a
    struct.get $box_i64 $v
    local.get $b
    struct.get $box_i64 $v
    i64.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_arr_any (param $a (ref null $arr_any)) (param $b (ref null $arr_any)) (result i32)
    (local $i i32)
    local.get $a
    array.len
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
    local.get $a
    array.len
    i32.ge_u
    br_if $brk
    local.get $a
    local.get $i
    array.get $arr_any
    local.get $b
    local.get $i
    array.get $arr_any
    call $__unk_eq
    i32.eqz
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
  (func $__unk_eq_ref (param $a anyref) (param $b anyref) (result i32)
    local.get $a
    ref.is_null
    local.get $b
    ref.is_null
    i32.or
    (if
      (then
    local.get $a
    ref.is_null
    local.get $b
    ref.is_null
    i32.and
    return
      )
    )
    local.get $a
    ref.cast (ref null eq)
    local.get $b
    ref.cast (ref null eq)
    ref.eq
    (if
      (then
    i32.const 1
    return
      )
    )
    local.get $a
    ref.test (ref null $box_i64)
    (if
      (then
    local.get $b
    ref.test (ref null $box_i64)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $box_i64)
    local.get $b
    ref.cast (ref null $box_i64)
    call $__unk_eq_s4
    return
      )
    )
    local.get $a
    ref.test (ref null $arr_any)
    (if
      (then
    local.get $b
    ref.test (ref null $arr_any)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $arr_any)
    local.get $b
    ref.cast (ref null $arr_any)
    call $__unk_eq_arr_any
    return
      )
    )
    i32.const 0
  )
  (func $__print_tagged_raw (param $v anyref)
    unreachable
  )
  (func $__print_ebox (param $v anyref) (result i32)
    i32.const 0
  )
  (func $__print_arrs (param $v anyref) (result i32)
    local.get $v
    ref.test (ref null $arr_any)
    (if
      (then
    local.get $v
    ref.cast (ref null $arr_any)
    call $__pr0
    i32.const 1
    return
      )
    )
    i32.const 0
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
  (func $__str_concat (param $a (ref null $str)) (param $b (ref null $str)) (result (ref null $str))
    (local $r (ref null $str)) (local $alen i32) (local $blen i32)
    local.get $a
    array.len
    local.set $alen
    local.get $b
    array.len
    local.set $blen
    local.get $alen
    local.get $blen
    i32.add
    array.new_default $str
    local.set $r
    local.get $r
    i32.const 0
    local.get $a
    i32.const 0
    local.get $alen
    array.copy $str $str
    local.get $r
    local.get $alen
    local.get $b
    i32.const 0
    local.get $blen
    array.copy $str $str
    local.get $r
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
  (data $__d0 "number ")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "text ")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "other")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "i32")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "f64")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "string")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "bool")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "a")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "s")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "hi")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "null")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 "[")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (data $__d12 ", ")
  (global $__s12 (mut (ref null $str)) (ref.null $str))
  (data $__d13 "]")
  (global $__s13 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 7
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 5
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 5
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 3
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 3
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 6
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 4
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
    i32.const 2
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 4
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 1
    array.new_data $str $__d11
    global.set $__s11
    i32.const 0
    i32.const 2
    array.new_data $str $__d12
    global.set $__s12
    i32.const 0
    i32.const 1
    array.new_data $str $__d13
    global.set $__s13
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
number 3
text a
other
i32 f64 string bool
true false
true hi
true
false true true
[1, "a", true]
```
