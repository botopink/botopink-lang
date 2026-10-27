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
    (type $var_Opt_None (sub final $__decl (struct (field $ti (ref null $__tinfo)))))
    (type $brand_var_Opt_None (struct (field i32) (field i32) (field f32) (field f32) (field f64) (field i64) (field i32) (field f64) (field f32) (field i64) (field i32) (field i64) (field i32) (field f32) (field f64) (field i64) (field i32) (field i64) (field f64) (field i64) (field i32) (field i32) (field i64) (field i64) (field i64) (field f64) (field f64) (field f64) (field i32) (field i32) (field i32) (field i32)))
  )
  (rec
    (type $var_Opt_Some (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut i32)))))
    (type $brand_var_Opt_Some (struct (field f64) (field f32) (field i64) (field f32) (field f64) (field f32) (field f64) (field f32) (field f64) (field i64) (field f64) (field i64) (field i32) (field f32) (field f32) (field i32) (field i32) (field f32) (field i32) (field i64) (field i64) (field i32) (field f64) (field f32) (field f32) (field i32) (field f32) (field f32) (field i64) (field i64) (field i64) (field i64)))
  )
  (import "std@__rt" "__ti_register" (func $__ti_register (param structref)))
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (global $__cap (import "std@__rt" "__cap") (mut arrayref))
  (global $__cap_depth (import "std@__rt" "__cap_depth") (mut i32))
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
    call $__new_33
    call $describe
    call $__print_str
    call $__new_31
    call $describe
    call $__print_str
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__eq_Opt (param $a anyref) (param $b anyref) (result i32)
    local.get $a
    ref.test (ref null $var_Opt_None)
    (if
      (then
    local.get $b
    ref.test (ref null $var_Opt_None)
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    i32.const 1
    return
      )
    )
    local.get $a
    ref.test (ref null $var_Opt_Some)
    (if
      (then
    local.get $b
    ref.test (ref null $var_Opt_Some)
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    ref.cast (ref null $var_Opt_Some)
    struct.get $var_Opt_Some $f0
    local.get $b
    ref.cast (ref null $var_Opt_Some)
    struct.get $var_Opt_Some $f0
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    i32.const 1
    return
      )
    )
    i32.const 0
  )
  (func $__pr0 (param $v (ref null $var_Opt_None))
    global.get $__s2
    call $__print_str_raw
  )
  (func $__tip1 (param $v anyref)
    local.get $v
    ref.cast (ref null $var_Opt_None)
    call $__pr0
  )
  (func $__tie1 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $var_Opt_None)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__eq_Opt
  )
  (func $__pr2 (param $v i32)
    local.get $v
    call $__print_i32_raw
  )
  (func $__pr1 (param $v (ref null $var_Opt_Some))
    global.get $__s4
    call $__print_str_raw
    global.get $__s5
    call $__print_str_raw
    global.get $__s1
    call $__print_str_raw
    local.get $v
    struct.get $var_Opt_Some $f0
    call $__pr2
    global.get $__s6
    call $__print_str_raw
  )
  (func $__tip2 (param $v anyref)
    local.get $v
    ref.cast (ref null $var_Opt_Some)
    call $__pr1
  )
  (func $__tie2 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $var_Opt_Some)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__eq_Opt
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
  (func $__cap_begin (result (ref null $str))
    (local $o (ref null $str))
    global.get $__cap
    ref.cast (ref null $str)
    local.set $o
    i32.const 0
    array.new_default $str
    global.set $__cap
    global.get $__cap_depth
    i32.const 1
    i32.add
    global.set $__cap_depth
    local.get $o
  )
  (func $__cap_end (param $o (ref null $str)) (result (ref null $str))
    (local $s (ref null $str))
    global.get $__cap
    ref.cast (ref null $str)
    local.set $s
    local.get $o
    global.set $__cap
    global.get $__cap_depth
    i32.const 1
    i32.sub
    global.set $__cap_depth
    local.get $s
  )
  (data $__d0 "empty")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "value: ")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "Opt.None")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "test@main.Opt.None")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "Opt.Some")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "(")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 ")")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "test@main.Opt.Some")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
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
    i32.const 0
    i32.const 8
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 18
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 8
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
    i32.const 18
    array.new_data $str $__d7
    global.set $__s7
    call $__init_types
  )
  (func $__new_33 (param $f0 i32) (result (ref null $var_Opt_Some))
    global.get $__ti_33
    local.get $f0
    struct.new $var_Opt_Some
  )
  (func $__new_31 (result (ref null $var_Opt_None))
    global.get $__ti_31
    struct.new $var_Opt_None
  )
  (global $__ti_33 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_31 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (elem declare func $__tip1 $__tie1 $__tip2 $__tie2)
  (func $__init_types
    global.get $__s3
    ref.func $__tip1
    ref.func $__tie1
    ref.null func
    i32.const 1
    struct.new $__tinfo
    global.set $__ti_31
    global.get $__ti_31
    call $__ti_register
    global.get $__s7
    ref.func $__tip2
    ref.func $__tie2
    ref.null func
    i32.const 1
    struct.new $__tinfo
    global.set $__ti_33
    global.get $__ti_33
    call $__ti_register
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
value: 42
empty
```
