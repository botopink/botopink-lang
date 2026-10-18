----- SOURCE CODE -- main.bp
```botopink
fn render(words: Array<string>) -> string {
    var out = "";
    var count = 0;
    val emit = { w ->
        out = out + "<" + w + ">";
        count = count + 1;
    };
    emit("start");
    for (words) { w -> emit(w); };
    return out + " " + count.toString();
}
fn main() {
    print(render(["a", "b"]));
}

import {io.terminal.print} from "std";
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $closure (sub (struct (field $idx i32) (field $mark i32))))
    (type $env0 (sub final $closure (struct (field $idx i32) (field $mark i32) (field $c0 (mut (ref null $str))) (field $c1 (mut i32)))))
    (type $box_i32 (struct (field $v i32)))
    (type $arr_any (array (mut anyref)))
  )
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (table funcref (elem $__lambda0))
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $render (param $words (ref null $arr_any)) (result (ref null $str))
    (local $out (ref null $str))
    (local $count i32)
    (local $emit (ref null $closure))
    (local $w i32)
    (local $__fnv0 (ref null $closure))
    (local $__iter1 (ref null $arr_any))
    (local $__idx1 i32)
    (local $__len1 i32)
    (local $w__sh0 (ref null $str))
    (local $__fnv2 (ref null $closure))
    global.get $__s0
    local.set $out
    i32.const 0
    local.set $count
    i32.const 0
    i32.const 0
    local.get $out ;; capture out
    local.get $count ;; capture count
    struct.new $env0
    local.set $emit
    local.get $emit
    local.set $__fnv0
    local.get $__fnv0
    ref.cast (ref null $env0)
    local.get $out
    struct.set $env0 $c0 ;; sync out into env
    local.get $__fnv0
    ref.cast (ref null $env0)
    local.get $count
    struct.set $env0 $c1 ;; sync count into env
    local.get $__fnv0
    global.get $__s1
    local.get $__fnv0
    struct.get $closure $idx ;; table index
    call_indirect (param (ref null $closure) anyref) (result anyref)
    local.get $__fnv0
    ref.cast (ref null $env0)
    struct.get $env0 $c0 ;; sync out from env
    local.set $out
    local.get $__fnv0
    ref.cast (ref null $env0)
    struct.get $env0 $c1 ;; sync count from env
    local.set $count
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    drop
    local.get $words
    local.set $__iter1
    local.get $__iter1
    array.len
    local.set $__len1
    i32.const 0
    local.set $__idx1
    (block $__break
      (loop $__continue
        local.get $__idx1
        local.get $__len1
        i32.ge_s
        br_if $__break
        local.get $__iter1
        local.get $__idx1
        array.get $arr_any
    ref.cast (ref null $str)
        local.set $w__sh0
    local.get $emit
    local.set $__fnv2
    local.get $__fnv2
    ref.cast (ref null $env0)
    local.get $out
    struct.set $env0 $c0 ;; sync out into env
    local.get $__fnv2
    ref.cast (ref null $env0)
    local.get $count
    struct.set $env0 $c1 ;; sync count into env
    local.get $__fnv2
    local.get $w__sh0
    local.get $__fnv2
    struct.get $closure $idx ;; table index
    call_indirect (param (ref null $closure) anyref) (result anyref)
    local.get $__fnv2
    ref.cast (ref null $env0)
    struct.get $env0 $c0 ;; sync out from env
    local.set $out
    local.get $__fnv2
    ref.cast (ref null $env0)
    struct.get $env0 $c1 ;; sync count from env
    local.set $count
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    drop
        local.get $__idx1
        i32.const 1
        i32.add
        local.set $__idx1
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $out
    global.get $__s2
    call $__str_concat
    local.get $count
    call $__std_number_i32ToString
    call $__str_concat
    return
  )
  (func $main
    (local $__mem0 i32)
    global.get $__s3
    global.get $__s4
    array.new_fixed $arr_any 2
    call $render
    call $__print_str
  )
  (func $__lambda0__b (param $__env (ref null $env0)) (param $w (ref null $str)) (result i32)
    (local $out (ref null $str))
    (local $count i32)
    local.get $__env
    struct.get $env0 $c0
    local.set $out
    local.get $__env
    struct.get $env0 $c1
    local.set $count
    local.get $out
    global.get $__s5
    call $__str_concat
    local.get $w
    call $__str_concat
    global.get $__s6
    call $__str_concat
    local.set $out
    local.get $__env
    local.get $out
    struct.set $env0 $c0 ;; write out back to env
    local.get $count
    i32.const 1
    global.get $__s7
    call $__i32_add_chk
    local.set $count
    local.get $__env
    local.get $count
    struct.set $env0 $c1 ;; write count back to env
    i32.const 0
  )
  (func $__lambda0 (param $__env (ref null $closure)) (param $__a0 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env0)
    local.get $__a0
    ref.cast (ref null $str)
    call $__lambda0__b
    struct.new $box_i32
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
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
  (func $__alloc (param $n i32) (result i32)
    (local $p i32) (local $e i32)
    global.get $__heap_ptr
    local.set $p
    local.get $p
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    local.set $e
    local.get $e
    local.get $p
    i32.lt_u
    (if
      (then
        unreachable
      )
    )
    local.get $e
    memory.size
    i32.const 16
    i32.shl
    i32.gt_u
    (if
      (then
        local.get $e
        i32.const 65535
        i32.add
        i32.const 16
        i32.shr_u
        memory.size
        i32.sub
        memory.grow
        i32.const -1
        i32.eq
        (if
          (then
            unreachable
          )
        )
      )
    )
    local.get $e
    global.set $__heap_ptr
    local.get $p
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
  ;; std-wasm's .wat leaves (front 164 s3)
  (func $__std_number_i32ToString (param $v i32) (result (ref null $str))
    local.get $v
    i64.extend_i32_s
    call $__std_number_i64ToString
  )
  (func $__std_number_decimal (param $mag i64) (param $neg i32) (result (ref null $str))
    (local $n i32)
    (local $i i32)
    (local $t i64)
    (local $out (ref null $str))
    local.get $mag
    local.set $t
    (block $counted
      (loop $count
        local.get $n
        i32.const 1
        i32.add
        local.set $n
        local.get $t
        i64.const 10
        i64.div_u
        local.tee $t
        i64.eqz
        br_if $counted
        br $count
      )
    )
    local.get $n
    local.get $neg
    i32.add
    local.tee $i
    array.new_default $str
    local.set $out
    local.get $mag
    local.set $t
    (block $filled
      (loop $fill
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        local.get $out
        local.get $i
        local.get $t
        i64.const 10
        i64.rem_u
        i32.wrap_i64
        i32.const 48
        i32.add
        array.set $str
        local.get $t
        i64.const 10
        i64.div_u
        local.tee $t
        i64.eqz
        br_if $filled
        br $fill
      )
    )
    local.get $neg
    (if
      (then
        local.get $out
        i32.const 0
        i32.const 45
        array.set $str
      )
    )
    local.get $out
  )
  (func $__std_number_i64ToString (param $v i64) (result (ref null $str))
    local.get $v
    i64.const 0
    i64.lt_s
    (if (result (ref null $str))
      (then
        i64.const 0
        local.get $v
        i64.sub
        i32.const 1
        call $__std_number_decimal
      )
      (else
        local.get $v
        i32.const 0
        call $__std_number_decimal
      )
    )
  )
  (data $__d0 "")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "start")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 " ")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "a")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "b")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "<")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 ">")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "integer overflow: + on i32 at main.bp:6:23")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 0
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 5
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
    i32.const 1
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 1
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 42
    array.new_data $str $__d7
    global.set $__s7
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
<start><a><b> 3
```
