----- SOURCE CODE -- main.bp
```botopink
iter fn two() -> Iter<i32> {
    yield 1;
    yield 2;
}
fn stepText(s: YieldStep<i32>) -> string {
    val t = case s {
        Yield(v) -> "yield " + v.toString();
        Done -> "done";
    };
    return t;
}
pub fn main() -> void {
    val it = two();
    print(stepText(it.next()));
    print(stepText(it.next()));
    print(stepText(it.next()));
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
    (type $var_YieldStep_Done (struct))
    (type $brand_var_YieldStep_Done (struct (field f64) (field f32) (field i32) (field i32) (field f32) (field f64) (field f64) (field i32) (field f32) (field i64) (field i32) (field f32) (field i32) (field f32) (field i64) (field f64) (field i64) (field i64) (field i64) (field i32) (field f64) (field f64) (field i32) (field f32) (field i64) (field f64) (field f64) (field f64) (field i32) (field f32) (field f64) (field i32)))
  )
  (rec
    (type $var_YieldStep_Yield (struct (field $f0 (mut anyref))))
    (type $brand_var_YieldStep_Yield (struct (field f32) (field i64) (field f32) (field f32) (field f32) (field i64) (field f64) (field i32) (field i32) (field i32) (field i32) (field i64) (field f64) (field i32) (field i64) (field i32) (field f64) (field f64) (field i64) (field i64) (field f32) (field f64) (field i32) (field f64) (field f32) (field f64) (field f64) (field i32) (field i32) (field i64) (field f64) (field f32)))
  )
  (rec
    (type $frame0 (struct (field $resume (mut i32))))
  )
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@number" "wat:number.i32ToString" (func $__std_number_i32ToString (param i32) (result (ref null $str))))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  ;; @Iter — a generator state machine (decision 105)
  (func $two (result (ref null $gen))
    (local $__fr (ref null $frame0))
    struct.new_default $frame0 ;; the frame: the resume index, then every local
    local.set $__fr
    i32.const 0 ;; live
    i32.const 5 ;; two__body
    local.get $__fr
    ref.null any
    ref.null $gen
    ref.null any ;; the environment
    i32.const 0
    struct.new $gen ;; runs nothing until its first next
  )
  (func $two__body (param $__gen (ref null $gen)) (result i32)
    (local $__frame (ref null $frame0))
    (local $__seek i32)
    (local $__state i32)
    local.get $__gen
    struct.get $gen $frame
    ref.cast (ref null $frame0)
    local.set $__frame
    local.get $__frame
    struct.get $frame0 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    (block $__yd1
    local.get $__seek
    (if
      (then
    local.get $__state
    i32.const 1
    i32.eq
    (if
      (then
    i32.const 0
    local.set $__seek
      )
    )
    br $__yd1 ;; resumed after this yield, or seeking past it
      )
    )
    local.get $__gen
    i32.const 1
    struct.new $box_i32
    struct.set $gen $value ;; the yitem
    local.get $__frame
    i32.const 1
    struct.set $frame0 $resume ;; the resume index
    i32.const 1
    return ;; an yitem
    )
      )
    )
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 2
    i32.ge_u
    local.get $__state
    i32.const 2
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    (block $__yd2
    local.get $__seek
    (if
      (then
    local.get $__state
    i32.const 2
    i32.eq
    (if
      (then
    i32.const 0
    local.set $__seek
      )
    )
    br $__yd2 ;; resumed after this yield, or seeking past it
      )
    )
    local.get $__gen
    i32.const 2
    struct.new $box_i32
    struct.set $gen $value ;; the yitem
    local.get $__frame
    i32.const 2
    struct.set $frame0 $resume ;; the resume index
    i32.const 1
    return ;; an yitem
    )
      )
    )
    i32.const 0 ;; the sequence ended
  )
  (func $stepText (param $s anyref) (result (ref null $str))
    (local $t (ref null $str))
    (local $v i32)
    (local $__case_0 anyref)
    local.get $s
    local.set $__case_0
    local.get $__case_0
    ref.test (ref null $var_YieldStep_Yield)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_YieldStep_Yield)
    struct.get $var_YieldStep_Yield $f0
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $v
    global.get $__s0
    local.get $v
    call $__std_number_i32ToString
    call $__str_concat
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_YieldStep_Done)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    global.get $__s1
      )
      (else
    ref.null $str
      )
    )
      )
    )
    local.set $t
    local.get $t
    return
  )
  (func $main (export "main")
    (local $it (ref null $gen))
    (local $__gc0 (ref null $gen))
    (local $__gc1 (ref null $gen))
    (local $__gc2 (ref null $gen))
    call $two
    local.set $it
    local.get $it
    local.set $__gc0
    local.get $__gc0
    call $__gen_next ;; the next yitem
    (if (result anyref)
      (then
    local.get $__gc0
    struct.get $gen $value
    struct.new $var_YieldStep_Yield
      )
      (else
    struct.new $var_YieldStep_Done
      )
    )
    call $stepText
    call $__print_str
    local.get $it
    local.set $__gc1
    local.get $__gc1
    call $__gen_next ;; the next yitem
    (if (result anyref)
      (then
    local.get $__gc1
    struct.get $gen $value
    struct.new $var_YieldStep_Yield
      )
      (else
    struct.new $var_YieldStep_Done
      )
    )
    call $stepText
    call $__print_str
    local.get $it
    local.set $__gc2
    local.get $__gc2
    call $__gen_next ;; the next yitem
    (if (result anyref)
      (then
    local.get $__gc2
    struct.get $gen $value
    struct.new $var_YieldStep_Yield
      )
      (else
    struct.new $var_YieldStep_Done
      )
    )
    call $stepText
    call $__print_str
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__gen_next (param $g (ref null $gen)) (result i32)
    (local $r i32)
    local.get $g
    struct.get $gen $state
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $g
    call $__gen_resume
    local.tee $r
    i32.eqz
    (if
      (then
    local.get $g
    i32.const 1
    struct.set $gen $state ;; ended
    local.get $g
    ref.null struct
    struct.set $gen $frame ;; its frame dropped
      )
    )
    local.get $r
  )
  (func $__gen_resume (param $g (ref null $gen)) (result i32)
    (local $k i32)
    local.get $g
    struct.get $gen $kind
    local.set $k
    local.get $k
    i32.const 0
    i32.eq
    (if
      (then
    local.get $g
    struct.get $gen $left
    i32.const 0
    i32.le_s
    (if
      (then
    local.get $g
    struct.get $gen $src
    call $__gen_close ;; the count is reached: its source
    i32.const 0
    return
      )
    )
    local.get $g
    local.get $g
    struct.get $gen $left
    i32.const 1
    i32.sub
    struct.set $gen $left
    local.get $g
    struct.get $gen $src
    call $__gen_next
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $g
    local.get $g
    struct.get $gen $src
    struct.get $gen $value
    struct.set $gen $value
    i32.const 1
    return
      )
    )
    local.get $k
    i32.const 1
    i32.eq
    (if
      (then
    (block $__break
      (loop $__continue
    local.get $g
    struct.get $gen $left
    i32.const 0
    i32.le_s
    br_if $__break
    local.get $g
    local.get $g
    struct.get $gen $left
    i32.const 1
    i32.sub
    struct.set $gen $left
    local.get $g
    struct.get $gen $src
    call $__gen_next
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    br $__continue
      )
    )
    local.get $g
    struct.get $gen $src
    call $__gen_next
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $g
    local.get $g
    struct.get $gen $src
    struct.get $gen $value
    struct.set $gen $value
    i32.const 1
    return
      )
    )
    local.get $k
    i32.const 5
    i32.eq
    (if
      (then
    local.get $g
    call $two__body
    return
      )
    )
    unreachable
  )
  (func $__gen_close (param $g (ref null $gen))
    local.get $g
    ref.is_null
    (if
      (then
    return
      )
    )
    local.get $g
    struct.get $gen $kind
    i32.const 5
    i32.lt_u
    (if
      (then
    local.get $g
    struct.get $gen $src
    call $__gen_close ;; its source
      )
      (else
      )
    )
    local.get $g
    i32.const 1
    struct.set $gen $state ;; ended
    local.get $g
    ref.null struct
    struct.set $gen $frame ;; its frame dropped
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
  (data $__d0 "yield ")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "done")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 6
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 4
    array.new_data $str $__d1
    global.set $__s1
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
yield 1
yield 2
done
```
