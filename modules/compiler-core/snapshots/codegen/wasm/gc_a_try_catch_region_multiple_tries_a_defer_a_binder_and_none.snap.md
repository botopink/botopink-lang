----- SOURCE CODE -- main.bp
```botopink
fn half(n: i32) -> Result<i32, string> {
    if (n % 2 == 0) {
        return n / 2;
    }
    throw "odd";
}

fn twice(n: i32) -> i32 {
    return try {
        defer print("deferred");
        val a = try half(n);
        val b = try half(a);
        b
    } catch { e ->
        print("caught: " + e);
        -1
    };
}

fn unbound(n: i32) -> i32 {
    return try {
        try half(n)
    } catch {
        -99
    };
}

pub fn main() -> void {
    print(twice(8));
    print(twice(3));
    print(unbound(4));
    print(unbound(3));
}

import {io.terminal.print} from "std";
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
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (tag $__bp_panic (param anyref))
  (func $half (param $n i32) (result (ref null $result))
    local.get $n
    i32.const 2
    global.get $__s0
    call $__i32_nz
    i32.rem_s
    i32.const 0
    i32.eq
    (if (result (ref null $result))
      (then
    i32.const 0
    local.get $n
    i32.const 2
    global.get $__s1
    global.get $__s2
    call $__i32_divs
    struct.new $box_i32
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 1
    global.get $__s3
    struct.new $result
    return
  )
  (func $twice (param $n i32) (result i32)
    (local $_try0 i32)
    (local $__rg_err0 (ref null $result))
    (local $__case_0 i32)
    (local $__defer_exc1 anyref)
    (local $__defer_ran1 i32)
    (local $a i32)
    (local $__gc0 (ref null $result))
    (local $b i32)
    (local $__gc1 (ref null $result))
    (local $e (ref null $str))
    (local $__case_1 i32)
    (block $__rg_done0 (result i32)
    (block $__rg_fail0
    i32.const 1
    local.set $__case_0
    (block $__defer_done1 (result i32)
    (block $__defer_h1 (result anyref)
    i32.const 0
    local.set $__defer_ran1
    (try_table (result i32) (catch $__bp_panic $__defer_h1)
    local.get $n
    call $half
    local.set $__gc0
    local.get $__gc0
    struct.get $result $tag
    (if
      (then
    local.get $__gc0
    local.set $__rg_err0
    i32.const 1
    local.set $__defer_ran1
    global.get $__s4
    call $__print_str
    br $__rg_fail0 ;; to the region's handler
      )
    )
    local.get $__gc0
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $a
    local.get $a
    call $half
    local.set $__gc1
    local.get $__gc1
    struct.get $result $tag
    (if
      (then
    local.get $__gc1
    local.set $__rg_err0
    i32.const 1
    local.set $__defer_ran1
    global.get $__s4
    call $__print_str
    br $__rg_fail0 ;; to the region's handler
      )
    )
    local.get $__gc1
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $b
    local.get $b
    )
    global.get $__s4
    call $__print_str
    br $__defer_done1
    )
    local.set $__defer_exc1
    local.get $__defer_ran1
    i32.eqz
    (if
      (then
    global.get $__s4
    call $__print_str
      )
    )
    local.get $__defer_exc1
    throw $__bp_panic
    )
    br $__rg_done0
    )
    local.get $__rg_err0
    struct.get $result $payload ;; the error payload
    ref.cast (ref null $str)
    local.set $e
    i32.const 1
    local.set $__case_1
    global.get $__s5
    local.get $e
    call $__str_concat
    call $__print_str
    i32.const 0
    i32.const 1
    global.get $__s6
    call $__i32_sub_chk
    )
    return
  )
  (func $unbound (param $n i32) (result i32)
    (local $_try0 i32)
    (local $__rg_err1 (ref null $result))
    (local $__case_0 i32)
    (local $__gc2 (ref null $result))
    (local $__case_1 i32)
    (block $__rg_done1 (result i32)
    (block $__rg_fail1
    i32.const 1
    local.set $__case_0
    local.get $n
    call $half
    local.set $__gc2
    local.get $__gc2
    struct.get $result $tag
    (if
      (then
    local.get $__gc2
    local.set $__rg_err1
    br $__rg_fail1 ;; to the region's handler
      )
    )
    local.get $__gc2
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    br $__rg_done1
    )
    i32.const 1
    local.set $__case_1
    i32.const 0
    i32.const 99
    global.get $__s7
    call $__i32_sub_chk
    )
    return
  )
  (func $main (export "main")
    i32.const 8
    call $twice
    call $__print_i32
    i32.const 3
    call $twice
    call $__print_i32
    i32.const 4
    call $unbound
    call $__print_i32
    i32.const 3
    call $unbound
    call $__print_i32
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (local $__c anyref)
    (block $__uncaught (result anyref)
    (try_table (catch $__bp_panic $__uncaught)
    (call $main)
    )
    return
    )
    local.set $__c ;; an abort nothing caught (decision 518)
    local.get $__c
    ref.cast (ref null $exn)
    struct.get $exn $print ;; print
    (if
      (then
      local.get $__c
      ref.cast (ref null $exn)
      struct.get $exn $msg ;; the message
      call $__panic_fail
      )
    )
    unreachable
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
  (func $__panic_raise (param $msg (ref null $str)) (param $print i32)
    local.get $msg
    local.get $print
    struct.new $exn
    throw $__bp_panic
  )
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    i32.const 1
    call $__panic_raise
    unreachable
  )
  (func $__i32_divs (param $a i32) (param $b i32) (param $site (ref null $str)) (param $osite (ref null $str)) (result i32)
    local.get $b
    i32.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    i32.const -2147483648
    i32.eq
    local.get $b
    i32.const -1
    i32.eq
    i32.and
    (if
      (then
        local.get $osite
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    local.get $b
    i32.div_s
  )
  (func $__i64_divs (param $a i64) (param $b i64) (param $site (ref null $str)) (param $osite (ref null $str)) (result i64)
    local.get $b
    i64.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    i64.const -9223372036854775808
    i64.eq
    local.get $b
    i64.const -1
    i64.eq
    i32.and
    (if
      (then
        local.get $osite
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    local.get $b
    i64.div_s
  )
  (func $__i32_nz (param $b i32) (param $site (ref null $str)) (result i32)
    local.get $b
    i32.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $b
  )
  (func $__i64_nz (param $b i64) (param $site (ref null $str)) (result i64)
    local.get $b
    i64.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $b
  )
  (data $__d0 "integer division by zero: % on i32 at main.bp:2:11")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "integer division by zero: / on i32 at main.bp:3:18")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "integer overflow: / on i32 at main.bp:3:18")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "odd")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "deferred")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "caught: ")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "integer overflow: - on i32 at main.bp:16:9")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "integer overflow: - on i32 at main.bp:24:9")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 50
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 50
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 42
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 3
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 8
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 8
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 42
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 42
    array.new_data $str $__d7
    global.set $__s7
  )
  (@custom "botopink.needs" "exceptions\0agc\0a")
)
```

----- RUN LOG -----
```logs
deferred
2
deferred
caught: odd
-1
2
-99
```
