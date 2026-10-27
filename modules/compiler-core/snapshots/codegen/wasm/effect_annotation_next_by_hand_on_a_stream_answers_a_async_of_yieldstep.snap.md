----- SOURCE CODE -- main.bp
```botopink
async iter fn countdown(n: i32) -> AsyncIter<i32> {
    var i = n;
    while (i > 0) {
        yield i;
        i = i - 1;
    };
}
fn stepText(s: YieldStep<i32>) -> string {
    val t = case s {
        Yield(v) -> "yield " + v.toString();
        Done -> "done";
    };
    return t;
}
async fn run() -> Async<void> {
    val s = countdown(1);
    print(stepText(await s.next()));
    print(stepText(await s.next()));
}
pub fn main() -> void {
    run();
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
  (rec
    (type $var_YieldStep_Done (sub final $__decl (struct (field $ti (ref null $__tinfo)))))
    (type $brand_var_YieldStep_Done (struct (field f64) (field f32) (field i32) (field i32) (field f32) (field f64) (field f64) (field i32) (field f32) (field i64) (field i32) (field f32) (field i32) (field f32) (field i64) (field f64) (field i64) (field i64) (field i64) (field i32) (field f64) (field f64) (field i32) (field f32) (field i64) (field f64) (field f64) (field f64) (field i32) (field f32) (field f64) (field i32)))
  )
  (rec
    (type $var_YieldStep_Yield (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut anyref)))))
    (type $brand_var_YieldStep_Yield (struct (field f32) (field i64) (field f32) (field f32) (field f32) (field i64) (field f64) (field i32) (field i32) (field i32) (field i32) (field i64) (field f64) (field i32) (field i64) (field i32) (field f64) (field f64) (field i64) (field i64) (field f32) (field f64) (field i32) (field f64) (field f32) (field f64) (field f64) (field i32) (field i32) (field i64) (field f64) (field f32)))
  )
  (rec
    (type $frame0 (struct (field $resume (mut i32)) (field $s0 (mut i32)) (field $s1 (mut i32))))
    (type $frame1 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $gen))) (field $s1 (mut (ref null $gen))) (field $s2 (mut (ref null $gen)))))
  )
  (import "std@__rt" "__ti_register" (func $__ti_register (param structref)))
  (import "std@__rt" "__print_decl" (func $__print_decl (param anyref)))
  (import "std@__rt" "__eq_decl" (func $__eq_decl (param anyref anyref) (result i32)))
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@number" "wat:number.i32ToString" (func $__abi___std_number_i32ToString (param i32) (result arrayref)))
  (import "std@number" "wat:number.i64ToString" (func $__abi___std_number_i64ToString (param i64) (result arrayref)))
  (import "std@number" "wat:number.u64ToString" (func $__abi___std_number_u64ToString (param i64) (result arrayref)))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  ;; @AsyncIter — a generator state machine (decision 105)
  (func $countdown (param $n i32) (result (ref null $gen))
    (local $__fr (ref null $frame0))
    struct.new_default $frame0 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $n
    struct.set $frame0 $s0
    i32.const 0 ;; live
    i32.const 5 ;; countdown__body
    local.get $__fr
    ref.null any
    ref.null $gen
    ref.null any ;; the environment
    i32.const 0
    struct.new $gen ;; runs nothing until its first next
  )
  (func $countdown__body (param $__gen (ref null $gen)) (result i32)
    (local $n i32)
    (local $i i32)
    (local $__frame (ref null $frame0))
    (local $__seek i32)
    (local $__state i32)
    local.get $__gen
    struct.get $gen $frame
    ref.cast (ref null $frame0)
    local.set $__frame
    local.get $__frame
    struct.get $frame0 $s0
    local.set $n
    local.get $__frame
    struct.get $frame0 $s1
    local.set $i
    local.get $__frame
    struct.get $frame0 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $n
    local.set $i
      )
    )
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
    (block $__break
      (loop $__continue
    local.get $__seek
    (if (result i32)
      (then
    i32.const 1 ;; re-entering: inside an iteration
      )
      (else
    local.get $i
    i32.const 0
    i32.gt_s
      )
    )
        i32.eqz
        br_if $__break
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
    local.get $i
    struct.new $box_i32
    struct.set $gen $value ;; the yitem
    local.get $__frame
    local.get $n
    struct.set $frame0 $s0
    local.get $__frame
    local.get $i
    struct.set $frame0 $s1
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
    (if
      (then
    local.get $i
    i32.const 1
    global.get $__s0
    call $__i32_sub_chk
    local.set $i
      )
    )
        br $__continue
      )
    )
    i32.const 0
    drop
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
    global.get $__s1
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
    global.get $__s2
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
  ;; @Async — a state machine (decision 392)
  (func $run (result (ref null $task))
    (local $__fr (ref null $frame1))
    struct.new_default $frame1 ;; the frame: the resume index, then every local
    local.set $__fr
    i32.const 0 ;; run__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $run__body (param $__task (ref null $task)) (result i32)
    (local $s (ref null $gen))
    (local $__frame (ref null $frame1))
    (local $__seek i32)
    (local $__state i32)
    (local $__gc0 (ref null $gen))
    (local $__gc1 (ref null $gen))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame1)
    local.set $__frame
    local.get $__frame
    struct.get $frame1 $s0
    local.set $s
    local.get $__frame
    struct.get $frame1 $s1
    local.set $__gc0
    local.get $__frame
    struct.get $frame1 $s2
    local.set $__gc1
    local.get $__frame
    struct.get $frame1 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    (if
      (then
    i32.const 1
    call $countdown
    local.set $s
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $s
    local.set $__gc0
    local.get $__gc0
    call $__gen_next ;; the next yitem
    (if (result anyref)
      (then
    local.get $__gc0
    struct.get $gen $value
    call $__new_24
      )
      (else
    call $__new_22
      )
    )
    call $stepText
    call $__print_str
      )
    )
    local.get $s
    local.set $__gc1
    local.get $__gc1
    call $__gen_next ;; the next yitem
    (if (result anyref)
      (then
    local.get $__gc1
    struct.get $gen $value
    call $__new_24
      )
      (else
    call $__new_22
      )
    )
    call $stepText
    call $__print_str
    i32.const 0
  )
  (func $run__step (param $__task (ref null $task))
    (local $__v i32)
    local.get $__task
    call $run__body
    local.set $__v
    global.get $__task_suspended
    (if
      (then
    i32.const 0
    global.set $__task_suspended
    return
      )
    )
    local.get $__task
    local.get $__v
    struct.new $box_i32
    call $__task_settle
  )
  (func $main (export "main") (result i32)
    call $run
    drop
    i32.const 0
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
    drop
    call $__task_finish ;; the tasks main started
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
    call $countdown__body
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
  (func $__unk_print_q (param $v anyref)
    local.get $v
    ref.is_null
    (if
      (then
    global.get $__s6
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
  (func $__pr0 (param $v (ref null $var_YieldStep_Yield))
    global.get $__s3
    call $__print_str_raw
    global.get $__s4
    call $__print_str_raw
    global.get $__s5
    call $__print_str_raw
    local.get $v
    struct.get $var_YieldStep_Yield $f0
    call $__pr1
    global.get $__s7
    call $__print_str_raw
  )
  (func $__tip4 (param $v anyref)
    local.get $v
    ref.cast (ref null $var_YieldStep_Yield)
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
  (func $__tie4 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $var_YieldStep_Yield)
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
  (func $__pr2 (param $v (ref null $var_YieldStep_Done))
    global.get $__s9
    call $__print_str_raw
  )
  (func $__tip5 (param $v anyref)
    local.get $v
    ref.cast (ref null $var_YieldStep_Done)
    call $__pr2
  )
  (func $__tie5 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $var_YieldStep_Done)
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
  (func $__unk_eq_s4 (param $a (ref null $var_YieldStep_Yield)) (param $b (ref null $var_YieldStep_Yield)) (result i32)
    local.get $a
    struct.get $var_YieldStep_Yield $f0
    local.get $b
    struct.get $var_YieldStep_Yield $f0
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
  (func $__unk_eq_s5 (param $a (ref null $var_YieldStep_Done)) (param $b (ref null $var_YieldStep_Done)) (result i32)
    i32.const 1
  )
  (func $__unk_eq_s10 (param $a (ref null $box_i64)) (param $b (ref null $box_i64)) (result i32)
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
    ref.test (ref null $var_YieldStep_Yield)
    (if
      (then
    local.get $b
    ref.test (ref null $var_YieldStep_Yield)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $var_YieldStep_Yield)
    local.get $b
    ref.cast (ref null $var_YieldStep_Yield)
    call $__unk_eq_s4
    return
      )
    )
    local.get $a
    ref.test (ref null $var_YieldStep_Done)
    (if
      (then
    local.get $b
    ref.test (ref null $var_YieldStep_Done)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $var_YieldStep_Done)
    local.get $b
    ref.cast (ref null $var_YieldStep_Done)
    call $__unk_eq_s5
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
    call $__unk_eq_s10
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
  (func $__print_tagged_raw (param $v anyref)
    local.get $v
    ref.test (ref null $var_YieldStep_Yield)
    (if
      (then
    local.get $v
    ref.cast (ref null $var_YieldStep_Yield)
    call $__pr0
    return
      )
    )
    local.get $v
    ref.test (ref null $var_YieldStep_Done)
    (if
      (then
    local.get $v
    ref.cast (ref null $var_YieldStep_Done)
    call $__pr2
    return
      )
    )
    local.get $v
    ref.test (ref null $__decl)
    (if
      (then
    local.get $v
    call $__print_decl
    return
      )
    )
    unreachable
  )
  (func $__print_ebox (param $v anyref) (result i32)
    i32.const 0
  )
  (func $__print_arrs (param $v anyref) (result i32)
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
  (global $__task_head (mut (ref null $task)) (ref.null $task))
  (global $__task_tail (mut (ref null $task)) (ref.null $task))
  (global $__task_suspended (mut i32) (i32.const 0))
  (func $__task_new (param $kind i32) (param $frame structref) (result (ref null $task))
    i32.const 0
    ref.null $waiter
    ref.null any
    local.get $frame
    local.get $kind
    ref.null $task
    ref.null any
    i32.const 0
    struct.new $task
  )
  (func $__task_start (param $kind i32) (param $frame structref) (result (ref null $task))
    (local $t (ref null $task))
    local.get $kind
    local.get $frame
    call $__task_new
    local.tee $t
    call $__task_resume
    local.get $t
  )
  (func $__task_pending (param $t (ref null $task)) (result i32)
    local.get $t
    struct.get $task $state
    i32.eqz
  )
  (func $__task_listen (param $t (ref null $task)) (param $kind i32) (param $target (ref null $task)) (param $index i32)
    (local $n (ref null $waiter))
    local.get $t
    struct.get $task $waiters
    local.get $kind
    local.get $target
    local.get $index
    struct.new $waiter
    local.set $n
    local.get $t
    local.get $n
    struct.set $task $waiters
  )
  (func $__task_wait (param $t (ref null $task)) (param $w (ref null $task))
    local.get $t
    i32.const 0
    local.get $w
    i32.const 0
    call $__task_listen
  )
  (func $__task_settle (param $t (ref null $task)) (param $v anyref)
    local.get $t
    local.get $v
    struct.set $task $value
    local.get $t
    call $__task_wake
  )
  (func $__task_wake (param $t (ref null $task))
    (local $n (ref null $waiter)) (local $m (ref null $waiter)) (local $r (ref null $waiter)) (local $k i32) (local $w (ref null $task))
    local.get $t
    struct.get $task $state
    (if
      (then
        return
      )
    )
    local.get $t
    i32.const 1
    struct.set $task $state
    local.get $t
    struct.get $task $waiters
    local.set $n
    local.get $t
    ref.null $waiter
    struct.set $task $waiters
    local.get $t
    ref.null struct
    struct.set $task $frame
    (block $brk
      (loop $cont
        local.get $n
        ref.is_null
        br_if $brk
        local.get $n
        struct.get $waiter $next
        local.set $m
        local.get $n
        local.get $r
        struct.set $waiter $next
        local.get $n
        local.set $r
        local.get $m
        local.set $n
        br $cont
      )
    )
    (block $brk
      (loop $cont
        local.get $r
        ref.is_null
        br_if $brk
        local.get $r
        struct.get $waiter $kind
        local.set $k
        local.get $r
        struct.get $waiter $target
        local.set $w
        local.get $k
        i32.eqz
        (if
          (then
            local.get $w
            call $__task_enqueue
          )
        )
        local.get $k
        i32.const 1
        i32.eq
        (if
          (then
            local.get $w
            struct.get $task $state
            i32.eqz
            (if
              (then
                local.get $w
                local.get $t
                struct.get $task $value
                struct.set $task $value
                local.get $w
                call $__task_wake
              )
            )
          )
        )
        local.get $k
        i32.const 2
        i32.eq
        (if
          (then
            local.get $w
            struct.get $task $aux
            ref.cast (ref null $arr_any)
            local.get $r
            struct.get $waiter $slot
            local.get $t
            struct.get $task $value
            array.set $arr_any
            local.get $w
            local.get $w
            struct.get $task $left
            i32.const 1
            i32.sub
            struct.set $task $left
            local.get $w
            struct.get $task $left
            i32.eqz
            (if
              (then
                local.get $w
                local.get $w
                struct.get $task $aux
                struct.set $task $value
                local.get $w
                ref.null any
                struct.set $task $aux
                local.get $w
                call $__task_wake
              )
            )
          )
        )
        local.get $r
        struct.get $waiter $next
        local.set $r
        br $cont
      )
    )
  )
  (func $__task_enqueue (param $t (ref null $task))
    local.get $t
    ref.null $task
    struct.set $task $next
    global.get $__task_tail
    ref.is_null
    (if
      (then
        local.get $t
        global.set $__task_head
      )
      (else
        global.get $__task_tail
        local.get $t
        struct.set $task $next
      )
    )
    local.get $t
    global.set $__task_tail
  )
  (func $__task_drain
    (local $t (ref null $task))
    (block $brk
      (loop $cont
        global.get $__task_head
        local.tee $t
        ref.is_null
        br_if $brk
        local.get $t
        struct.get $task $next
        global.set $__task_head
        global.get $__task_head
        ref.is_null
        (if
          (then
            ref.null $task
            global.set $__task_tail
          )
        )
        local.get $t
        call $__task_resume
        br $cont
      )
    )
  )
  (func $__task_block_on (param $t (ref null $task)) (result (ref null $task))
    (local $r (ref null $task))
    (block $brk
      (loop $cont
        local.get $t
        struct.get $task $state
        br_if $brk
        global.get $__task_head
        local.tee $r
        ref.is_null
        (if
          (then
            unreachable
          )
        )
        local.get $r
        struct.get $task $next
        global.set $__task_head
        global.get $__task_head
        ref.is_null
        (if
          (then
            ref.null $task
            global.set $__task_tail
          )
        )
        local.get $r
        call $__task_resume
        br $cont
      )
    )
    local.get $t
  )
  (func $__task_finish
    (block $brk
      (loop $cont
        call $__task_drain
        call $__task_host_poll
        i32.eqz
        br_if $brk
        br $cont
      )
    )
  )
  (func $__task_resume (param $t (ref null $task))
    (local $k i32)
    local.get $t
    struct.get $task $kind ;; kind
    local.set $k
    local.get $k
    i32.const 0
    i32.eq
    (if
      (then
    local.get $t
    call $run__step
    return
      )
    )
    unreachable
  )
  (func $__task_host_poll (result i32)
    i32.const 0
  )
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  (func $__std_number_i32ToString (param $p0 i32) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_i32ToString
    ref.cast (ref null $str)
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
  (data $__d0 "integer overflow: - on i32 at main.bp:5:15")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "yield ")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "done")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "YieldStep.Yield")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "(")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "value: ")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "null")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 ")")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "test@main.YieldStep.Yield")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "YieldStep.Done")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "test@main.YieldStep.Done")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 42
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 6
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 4
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 15
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 1
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 7
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
    i32.const 25
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 14
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 24
    array.new_data $str $__d10
    global.set $__s10
    call $__init_types
  )
  (func $__new_24 (param $f0 anyref) (result (ref null $var_YieldStep_Yield))
    global.get $__ti_24
    local.get $f0
    struct.new $var_YieldStep_Yield
  )
  (func $__new_22 (result (ref null $var_YieldStep_Done))
    global.get $__ti_22
    struct.new $var_YieldStep_Done
  )
  (global $__ti_24 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_22 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (elem declare func $__tip4 $__tie4 $__tip5 $__tie5)
  (func $__init_types
    global.get $__s8
    ref.func $__tip4
    ref.func $__tie4
    ref.null func
    i32.const 1
    struct.new $__tinfo
    global.set $__ti_24
    global.get $__ti_24
    call $__ti_register
    global.get $__s10
    ref.func $__tip5
    ref.func $__tie5
    ref.null func
    i32.const 1
    struct.new $__tinfo
    global.set $__ti_22
    global.get $__ti_22
    call $__ti_register
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
yield 1
done
```
