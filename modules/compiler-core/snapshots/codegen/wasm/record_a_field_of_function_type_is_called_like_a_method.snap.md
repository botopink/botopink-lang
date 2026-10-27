----- SOURCE CODE -- main.bp
```botopink
type Cell(
    value: i32,
    set: fn(next: i32) -> i32,
)

fn mk(v: i32) -> Cell {
    return Cell(value: v, set: { next -> next + v });
}

pub fn main() -> void {
    val c = mk(5);
    print(c.value);
    print(c.set(9));
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
  (rec
    (type $rec_Cell (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut i32)) (field $f1 (mut (ref null $closure))))))
    (type $brand_rec_Cell (struct (field f32) (field f64) (field i64) (field i64) (field f32) (field i32) (field f32) (field f64) (field i64) (field i64) (field f64) (field i32) (field f64) (field f32) (field i32) (field i64) (field f64) (field f64) (field f32) (field f64) (field i32) (field i32) (field i32) (field i64) (field i64) (field f64) (field f64) (field f64) (field f64) (field f64) (field f64) (field i64)))
  )
  (rec
    (type $env0 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut i32)))))
  )
  (import "std@__rt" "__ti_register" (func $__ti_register (param structref)))
  (import "std@__rt" "__eq_decl" (func $__eq_decl (param anyref anyref) (result i32)))
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (elem declare func $__lambda0)
  (func $mk (param $v i32) (result (ref null $rec_Cell))
    (local $__mem0 i32)
    local.get $v
    ref.func $__lambda0
    i32.const 1 ;; arity
    i32.const 0
    local.get $v ;; capture v
    struct.new $env0
    call $__new_31
    return
  )
  (func $main (export "main")
    (local $c (ref null $rec_Cell))
    (local $__fnv0 (ref null $closure))
    i32.const 5
    call $mk
    local.set $c
    local.get $c
    struct.get $rec_Cell $f0
    call $__print_i32
    local.get $c
    struct.get $rec_Cell $f1
    local.set $__fnv0
    local.get $__fnv0
    i32.const 9
    struct.new $box_i32
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_1)
    call_ref $sig_1
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32
  )
  (func $__lambda0__b (param $__env (ref null $env0)) (param $next i32) (result i32)
    (local $v i32)
    local.get $__env
    struct.get $env0 $c0
    local.set $v
    local.get $next
    local.get $v
    global.get $__s0
    call $__i32_add_chk
  )
  (func $__lambda0 (type $sig_1) (param $__env (ref null $closure)) (param $__a0 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env0)
    local.get $__a0
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__lambda0__b
    struct.new $box_i32
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__pr1 (param $v i32)
    local.get $v
    call $__print_i32_raw
  )
  (func $__pr2 (param $v anyref)
    global.get $__s5
    call $__print_str_raw
    local.get $v
    ref.cast (ref null $closure)
    struct.get $closure $arity
    call $__print_i32_raw
  )
  (func $__pr0 (param $v (ref null $rec_Cell))
    global.get $__s1
    call $__print_str_raw
    global.get $__s2
    call $__print_str_raw
    global.get $__s3
    call $__print_str_raw
    local.get $v
    struct.get $rec_Cell $f0
    call $__pr1
    global.get $__s4
    call $__print_str_raw
    local.get $v
    struct.get $rec_Cell $f1
    call $__pr2
    global.get $__s6
    call $__print_str_raw
  )
  (func $__tip3 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Cell)
    call $__pr0
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
  (func $__tie3 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Cell)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__unk_eq_s3 (param $a (ref null $rec_Cell)) (param $b (ref null $rec_Cell)) (result i32)
    local.get $a
    struct.get $rec_Cell $f0
    local.get $b
    struct.get $rec_Cell $f0
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Cell $f1
    local.get $b
    struct.get $rec_Cell $f1
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
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
    ref.test (ref null $rec_Cell)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Cell)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Cell)
    local.get $b
    ref.cast (ref null $rec_Cell)
    call $__unk_eq_s3
    return
      )
    )
    local.get $a
    ref.test (ref null $__decl)
    local.get $b
    ref.test (ref null $__decl)
    i32.and
    (if
      (then
    local.get $a
    local.get $b
    call $__eq_decl
    return
      )
    )
    i32.const 0
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
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  (data $__d0 "integer overflow: + on i32 at main.bp:7:47")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "Cell")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "(")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "value: ")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 ", set: ")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "fn/")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 ")")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "test@main.Cell")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 42
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 4
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 1
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 7
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 7
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 3
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 1
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 14
    array.new_data $str $__d7
    global.set $__s7
    call $__init_types
  )
  (func $__new_31 (param $f0 i32) (param $f1 (ref null $closure)) (result (ref null $rec_Cell))
    global.get $__ti_31
    local.get $f0
    local.get $f1
    struct.new $rec_Cell
  )
  (global $__ti_31 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (elem declare func $__tip3 $__tie3)
  (func $__init_types
    global.get $__s7
    ref.func $__tip3
    ref.func $__tie3
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_31
    global.get $__ti_31
    call $__ti_register
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
5
14
```
