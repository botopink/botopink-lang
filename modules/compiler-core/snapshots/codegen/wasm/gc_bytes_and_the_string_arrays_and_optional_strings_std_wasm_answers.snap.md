----- SOURCE CODE -- main.bp
```botopink
pub fn main() -> void {
    val b = bytes.fromUtf8("hello");
    print(b.length());
    print(b.slice(1, 3).length());
    val c = b.concat(bytes.fromUtf8("!"));
    print(c.length());
    print(b == bytes.fromUtf8("hello"));
    val r = b.toUtf8();
    print(r);
    val parts = "a,b,c".split(",");
    print(parts);
    print("hello".at(1));
    print("hello".at(9));
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
  (import "std@bytes" "std:bytes.slice" (func $__std_bytes_slice (param i32 i32 i32) (result i32)))
  (import "std@bytes" "std:bytes.isUtf8" (func $__std_bytes_isUtf8 (param i32) (result i32)))
  (import "std@string" "std:text.split" (func $__std_text_split (param i32 i32) (result i32)))
  (import "std@string" "std:text.at" (func $__std_text_at (param i32 i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@number" "wat:number.i64ToString" (func $__abi___std_number_i64ToString (param i64) (result arrayref)))
  (import "std@number" "wat:number.u64ToString" (func $__abi___std_number_u64ToString (param i64) (result arrayref)))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $main (export "main")
    (local $b (ref null $str))
    (local $c (ref null $str))
    (local $r (ref null $result))
    (local $parts (ref null $arr_any))
    (local $__gc0 i32)
    (local $__gc1 i32)
    (local $__gc2 (ref null $str))
    (local $__gc3 i32)
    (local $__gc4 (ref null $str))
    (local $__gc5 (ref null $str))
    (local $__gc6 i32)
    (local $__gc7 (ref null $str))
    (local $__gc8 (ref null $str))
    (local $__gc9 i32)
    (local $__gc10 (ref null $str))
    (local $__gc11 i32)
    (local $__gc12 (ref null $str))
    (local $__gc13 i32)
    (local $__gc14 i32)
    (local $__gc15 (ref null $str))
    (local $__gc16 i32)
    (local $__gc17 (ref null $str))
    (local $__gc18 i32)
    (local $__gc19 i32)
    global.get $__s0
    local.set $b
    local.get $b
    array.len
    call $__print_i32
    local.get $b
    i32.const 1
    i32.const 3
    local.set $__gc0
    local.set $__gc1
    local.set $__gc2
    global.get $__heap_ptr
    local.set $__gc3
    local.get $__gc2
    call $__gc_to_lin_str
    local.get $__gc1
    local.get $__gc0
    call $__std_bytes_slice
    call $__lin_to_gc_str
    local.get $__gc3
    global.set $__heap_ptr
    array.len
    call $__print_i32
    local.get $b
    global.get $__s1
    call $__str_concat
    local.set $c
    local.get $c
    array.len
    call $__print_i32
    local.get $b
    global.get $__s0
    call $__str_eq
    call $__print_bool
    local.get $b
    local.set $__gc4
    local.get $__gc4
    local.set $__gc5
    global.get $__heap_ptr
    local.set $__gc6
    local.get $__gc5
    call $__gc_to_lin_str
    call $__std_bytes_isUtf8
    local.get $__gc6
    global.set $__heap_ptr
    (if (result (ref null $result))
      (then
    i32.const 0
    local.get $__gc4
    struct.new $result
      )
      (else
    i32.const 1
    global.get $__s2
    struct.new $result
      )
    )
    local.set $r
    local.get $r
    call $__pr0
    call $__print_nl
    global.get $__s6
    global.get $__s7
    local.set $__gc7
    local.set $__gc8
    global.get $__heap_ptr
    local.set $__gc9
    local.get $__gc8
    call $__gc_to_lin_str
    local.get $__gc7
    call $__gc_to_lin_str
    call $__std_text_split
    call $__lin_to_gc_strs
    local.get $__gc9
    global.set $__heap_ptr
    local.set $parts
    local.get $parts
    call $__pr2
    call $__print_nl
    global.get $__s0
    i32.const 1
    local.set $__gc11
    local.set $__gc12
    global.get $__heap_ptr
    local.set $__gc13
    local.get $__gc12
    call $__gc_to_lin_str
    local.get $__gc11
    call $__std_text_at
    local.tee $__gc14
    i32.eqz
    (if (result (ref null $str))
      (then
    ref.null $str
      )
      (else
    local.get $__gc14
    call $__lin_to_gc_str
      )
    )
    local.get $__gc13
    global.set $__heap_ptr
    local.tee $__gc10
    ref.is_null
    (if
      (then
    global.get $__s11
    call $__print_str_raw
      )
      (else
    local.get $__gc10
    call $__print_str_raw
      )
    )
    call $__print_nl
    global.get $__s0
    i32.const 9
    local.set $__gc16
    local.set $__gc17
    global.get $__heap_ptr
    local.set $__gc18
    local.get $__gc17
    call $__gc_to_lin_str
    local.get $__gc16
    call $__std_text_at
    local.tee $__gc19
    i32.eqz
    (if (result (ref null $str))
      (then
    ref.null $str
      )
      (else
    local.get $__gc19
    call $__lin_to_gc_str
      )
    )
    local.get $__gc18
    global.set $__heap_ptr
    local.tee $__gc15
    ref.is_null
    (if
      (then
    global.get $__s11
    call $__print_str_raw
      )
      (else
    local.get $__gc15
    call $__print_str_raw
      )
    )
    call $__print_nl
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__pr1 (param $v (ref null $str))
    local.get $v
    call $__print_quoted_raw
  )
  (func $__pr0 (param $v (ref null $result))
    local.get $v
    struct.get $result $tag
    (if
      (then
    global.get $__s3
    call $__print_str_raw
    local.get $v
    struct.get $result $payload
    ref.cast (ref null $str)
    call $__pr1
    global.get $__s4
    call $__print_str_raw
      )
      (else
    global.get $__s5
    call $__print_str_raw
    local.get $v
    struct.get $result $payload
    ref.cast (ref null $str)
    call $__pr1
    global.get $__s4
    call $__print_str_raw
      )
    )
  )
  (func $__pr2 (param $v (ref null $arr_any))
    (local $n i32)
    (local $i i32)
    global.get $__s8
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
    global.get $__s9
    call $__print_str_raw
      )
    )
    local.get $v
    local.get $i
    array.get $arr_any
    ref.cast (ref null $str)
    call $__pr1
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    global.get $__s10
    call $__print_str_raw
  )
  (func $__lin_to_gc_strs (param $p i32) (result (ref null $arr_any))
    (local $n i32)
    (local $i i32)
    (local $r (ref null $arr_any))
    local.get $p
    i32.load
    local.set $n
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
    local.get $p
    local.get $i
    i32.const 4
    i32.mul
    i32.add
    i32.load offset=4
    call $__lin_to_gc_str
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
  (func $__gc_to_lin_str (param $s (ref null $str)) (result i32)
    (local $n i32) (local $p i32) (local $i i32)
    local.get $s
    array.len
    local.set $n
    local.get $n
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
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
        i32.store8 offset=4
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
  )
  (func $__lin_to_gc_str (param $p i32) (result (ref null $str))
    (local $r (ref null $str)) (local $n i32) (local $i i32)
    local.get $p
    i32.load
    local.set $n
    local.get $n
    array.new_default $str
    local.set $r
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $r
        local.get $i
        local.get $p
        local.get $i
        i32.add
        i32.load8_u offset=4
        array.set $str
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $r
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
  (data $__d0 "hello")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "!")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "bytes.toUtf8: not valid UTF-8")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "Error(")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 ")")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "Ok(")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "a,b,c")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 ",")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "[")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 ", ")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "]")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 "null")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 5
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 1
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 29
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 6
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 1
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 3
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 5
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
    i32.const 1
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 4
    array.new_data $str $__d11
    global.set $__s11
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
5
2
6
true
Ok("hello")
["a", "b", "c"]
e
null
```
