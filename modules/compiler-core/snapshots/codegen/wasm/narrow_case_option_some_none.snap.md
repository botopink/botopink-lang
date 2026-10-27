----- SOURCE CODE -- main.bp
```botopink
type Opt { None, Some(value: i32) }
fn describe(opt: Opt) -> string {
    return case opt {
        None -> "empty";
        Some(v) -> "value: " + v;
    };
}
fn main() -> void {
    print(describe(Opt.Some(value: 42)));
    print(describe(Opt.None));
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
    (type $var_Opt_None (struct))
    (type $brand_var_Opt_None (struct (field i32) (field i32) (field f32) (field f32) (field f64) (field i64) (field i32) (field f64) (field f32) (field i64) (field i32) (field i64) (field i32) (field f32) (field f64) (field i64) (field i32) (field i64) (field f64) (field i64) (field i32) (field i32) (field i64) (field i64) (field i64) (field f64) (field f64) (field f64) (field i32) (field i32) (field i32) (field i32)))
  )
  (rec
    (type $var_Opt_Some (struct (field $f0 (mut i32))))
    (type $brand_var_Opt_Some (struct (field f64) (field f32) (field i64) (field f32) (field f64) (field f32) (field f64) (field f32) (field f64) (field i64) (field f64) (field i64) (field i32) (field f32) (field f32) (field i32) (field i32) (field f32) (field i32) (field i64) (field i64) (field i32) (field f64) (field f32) (field f32) (field i32) (field f32) (field f32) (field i64) (field i64) (field i64) (field i64)))
  )
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $describe (param $opt anyref) (result (ref null $str))
    (local $v i32)
    (local $__case_0 anyref)
    (local $__gc0 (ref null $str))
    local.get $opt
    local.set $__case_0
    local.get $__case_0
    ref.test (ref null $var_Opt_None)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    global.get $__s0
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_Opt_Some)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_Opt_Some)
    struct.get $var_Opt_Some $f0
    local.set $v
    global.get $__s1
    call $__cap_begin
    local.set $__gc0
    local.get $v
    call $__print_i32_raw
    local.get $__gc0
    call $__cap_end
    call $__str_concat
      )
      (else
    ref.null $str
      )
    )
      )
    )
    return
  )
  (func $main
    (local $__mem0 i32)
    i32.const 42
    struct.new $var_Opt_Some
    call $describe
    call $__print_str
    struct.new $var_Opt_None
    call $describe
    call $__print_str
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
  (func $__write_bytes (param $p i32) (param $n i32)
    (local $c (ref null $str)) (local $q (ref null $str)) (local $l i32) (local $i i32)
    global.get $__cap
    local.set $c
    local.get $c
    ref.is_null
    i32.eqz
    (if
      (then
        local.get $c
        array.len
        local.set $l
        local.get $l
        local.get $n
        i32.add
        array.new_default $str
        local.set $q
        local.get $q
        i32.const 0
        local.get $c
        i32.const 0
        local.get $l
        array.copy $str $str
        (block $brk
          (loop $cont
            local.get $i
            local.get $n
            i32.ge_u
            br_if $brk
            local.get $q
            local.get $l
            local.get $i
            i32.add
            local.get $p
            local.get $i
            i32.add
            i32.load8_u
            array.set $str
            local.get $i
            i32.const 1
            i32.add
            local.set $i
            br $cont
          )
        )
        local.get $q
        global.set $__cap
        return
      )
    )
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
  (global $__cap (mut (ref null $str)) (ref.null $str))
  (func $__cap_begin (result (ref null $str))
    (local $o (ref null $str))
    global.get $__cap
    local.set $o
    i32.const 0
    array.new_default $str
    global.set $__cap
    local.get $o
  )
  (func $__cap_end (param $o (ref null $str)) (result (ref null $str))
    (local $s (ref null $str))
    global.get $__cap
    local.set $s
    local.get $o
    global.set $__cap
    local.get $s
  )
  (data $__d0 "empty")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "value: ")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 5
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 7
    array.new_data $str $__d1
    global.set $__s1
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
value: 42
empty
```
