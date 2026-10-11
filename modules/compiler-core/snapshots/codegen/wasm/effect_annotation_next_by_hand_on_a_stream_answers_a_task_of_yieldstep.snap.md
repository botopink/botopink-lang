----- SOURCE CODE -- main.bp
```botopink
fn countdown(n: i32) -> @Stream<i32> {
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
fn run() -> @Task<void> {
    val s = countdown(1);
    @print(stepText(await s.next()));
    @print(stepText(await s.next()));
}
pub fn main() {
    run();
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\06\00\00\00yield ")
  (data (i32.const 268) "\04\00\00\00done")
  (data (i32.const 276) "\19\00\00\00V\0fYieldStep.Yield\01\05valuei")
  (data (i32.const 308) "\11\00\00\00V\0eYieldStep.Done\00")
  (global $__heap_ptr (mut i32) (i32.const 332))
  ;; @Stream — eager lowering
  (func $countdown (param $n i32) (result i32)
    (local $i i32)
    (local $__yield_fn i32)
    i32.const 0
    call $__arr_new
    local.set $__yield_fn
    local.get $n
    local.set $i
    (block $__break
      (loop $__continue
    local.get $i
    i32.const 0
    i32.gt_s
        i32.eqz
        br_if $__break
    local.get $__yield_fn
    local.get $i
    call $__arr_push
    local.set $__yield_fn
    local.get $i
    i32.const 1
    call $__i32_sub_chk
    local.set $i
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $__yield_fn ;; everything the body yielded
  )
  (func $stepText (param $s i32) (result i32)
    (local $t i32)
    (local $v i32)
    (local $__case_0 i32)
    local.get $s
    local.set $__case_0
    local.get $__case_0
    i32.load ;; variant tag
    i32.const 0 ;; Yield
    i32.eq
    (if (result i32)
      (then
    local.get $__case_0
    i32.load offset=4
    local.set $v
    i32.const 256
    local.get $v
    call $__i32_to_str
    call $__str_concat
      )
      (else
    local.get $__case_0
    i32.load ;; variant tag
    i32.const 1 ;; Done
    i32.eq
    (if (result i32)
      (then
    i32.const 268
      )
      (else
    i32.const 0
      )
    )
      )
    )
    local.set $t
    local.get $t
    return
  )
  ;; @Task — a state machine (decision 392)
  (func $run (result i32)
    (local $__fr i32)
    i32.const 64 ;; the frame: the resume index, then every local
    call $__alloc
    local.set $__fr
    i32.const 0 ;; run__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $run__body (param $__task i32) (result i32)
    (local $s i32)
    (local $__frame i32)
    (local $__seek i32)
    (local $__state i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    (local $__mem5 i32)
    local.get $__task
    i32.load offset=16
    local.set $__frame
    local.get $__frame
    i32.load offset=8
    local.set $s
    local.get $__frame
    i32.load offset=16
    local.set $__mem0
    local.get $__frame
    i32.load offset=24
    local.set $__mem1
    local.get $__frame
    i32.load offset=32
    local.set $__mem2
    local.get $__frame
    i32.load offset=40
    local.set $__mem3
    local.get $__frame
    i32.load offset=48
    local.set $__mem4
    local.get $__frame
    i32.load offset=56
    local.set $__mem5
    local.get $__frame
    i32.load ;; the resume index
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
    local.tee $__mem0
    i32.load ;; items left
    (if (result i32)
      (then
    i32.const 12
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 280
    i32.store
    local.get $__mem1
    i32.const 0
    i32.store offset=4
    local.get $__mem1
    local.get $__mem0
    i32.load offset=4 ;; the head
    i32.store offset=8
    local.get $__mem0
    i32.const 1
    local.get $__mem0
    i32.load
    call $__arr_slice
    local.set $s ;; s = the rest
    local.get $__mem1
    i32.const 4
    i32.add
      )
      (else
    i32.const 8
    call $__alloc
    local.set $__mem2
    local.get $__mem2
    i32.const 312
    i32.store
    local.get $__mem2
    i32.const 1
    i32.store offset=4
    local.get $__mem2
    i32.const 4
    i32.add
      )
    )
    call $stepText
    call $__print_str
      )
    )
    local.get $s
    local.tee $__mem3
    i32.load ;; items left
    (if (result i32)
      (then
    i32.const 12
    call $__alloc
    local.set $__mem4
    local.get $__mem4
    i32.const 280
    i32.store
    local.get $__mem4
    i32.const 0
    i32.store offset=4
    local.get $__mem4
    local.get $__mem3
    i32.load offset=4 ;; the head
    i32.store offset=8
    local.get $__mem3
    i32.const 1
    local.get $__mem3
    i32.load
    call $__arr_slice
    local.set $s ;; s = the rest
    local.get $__mem4
    i32.const 4
    i32.add
      )
      (else
    i32.const 8
    call $__alloc
    local.set $__mem5
    local.get $__mem5
    i32.const 312
    i32.store
    local.get $__mem5
    i32.const 1
    i32.store offset=4
    local.get $__mem5
    i32.const 4
    i32.add
      )
    )
    call $stepText
    call $__print_str
    i32.const 0
  )
  (func $run__step (param $__task i32)
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
    call $__task_settle_i32
  )
  (func $main (export "main") (result i32)
    call $run
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
    drop
    call $__task_finish ;; the tasks main started
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
  (func $__print_str_raw (param $s i32)
    local.get $s
    i32.const 256
    i32.lt_u
    (if
      (then
        ;; a pointer below the data floor is not a string
        unreachable
      )
    )
    local.get $s
    i32.const 4
    i32.add
    local.get $s
    i32.load
    call $__write_bytes
  )
  (func $__print_str (param $s i32)
    local.get $s
    call $__print_str_raw
    call $__print_nl
  )
  (func $__str_concat (param $a i32) (param $b i32) (result i32)
    (local $base i32) (local $alen i32) (local $blen i32)
    local.get $a
    i32.load
    local.set $alen
    local.get $b
    i32.load
    local.set $blen
    ;; allocate 4 (length prefix) + alen + blen
    i32.const 4
    local.get $alen
    i32.add
    local.get $blen
    i32.add
    call $__alloc
    local.set $base
    ;; store combined length prefix
    local.get $base
    local.get $alen
    local.get $blen
    i32.add
    i32.store
    ;; copy a's bytes: base+4 <- a+4
    local.get $base
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.add
    local.get $alen
    memory.copy
    ;; copy b's bytes: base+4+alen <- b+4
    local.get $base
    i32.const 4
    i32.add
    local.get $alen
    i32.add
    local.get $b
    i32.const 4
    i32.add
    local.get $blen
    memory.copy
    local.get $base
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
  (func $__i32_to_str (param $n i32) (result i32)
    (local $u i64) (local $pos i32) (local $len i32) (local $p i32) (local $neg i32)
    i32.const 160
    local.set $pos
    local.get $n
    i32.const 0
    i32.lt_s
    local.set $neg
    local.get $n
    i64.extend_i32_s
    local.set $u
    local.get $neg
    (if
      (then
        i64.const 0
        local.get $u
        i64.sub
        local.set $u
      )
    )
    (block $brk
      (loop $cont
        local.get $pos
        i32.const 1
        i32.sub
        local.set $pos
        local.get $pos
        local.get $u
        i64.const 10
        i64.rem_u
        i32.wrap_i64
        i32.const 48
        i32.add
        i32.store8
        local.get $u
        i64.const 10
        i64.div_u
        local.set $u
        local.get $u
        i64.eqz
        br_if $brk
        br $cont
      )
    )
    local.get $neg
    (if
      (then
        local.get $pos
        i32.const 1
        i32.sub
        local.set $pos
        local.get $pos
        i32.const 45
        i32.store8
      )
    )
    i32.const 160
    local.get $pos
    i32.sub
    local.set $len
    local.get $len
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $len
    i32.store
    local.get $p
    i32.const 4
    i32.add
    local.get $pos
    local.get $len
    memory.copy
    local.get $p
  )
  (func $__arr_new (param $n i32) (result i32)
    (local $p i32)
    local.get $n
    i32.const 1
    i32.add
    i32.const 4
    i32.mul
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
    local.get $p
  )
  (func $__arr_slice (param $xs i32) (param $a i32) (param $b i32) (result i32)
    (local $n i32) (local $cnt i32) (local $p i32)
    local.get $xs
    i32.load
    local.set $n
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $n
        local.get $a
        i32.add
        local.set $a
        local.get $a
        i32.const 0
        i32.lt_s
        (if
          (then
            i32.const 0
            local.set $a
          )
        )
      )
      (else
        local.get $a
        local.get $n
        i32.gt_s
        (if
          (then
            local.get $n
            local.set $a
          )
        )
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $n
        local.get $b
        i32.add
        local.set $b
        local.get $b
        i32.const 0
        i32.lt_s
        (if
          (then
            i32.const 0
            local.set $b
          )
        )
      )
      (else
        local.get $b
        local.get $n
        i32.gt_s
        (if
          (then
            local.get $n
            local.set $b
          )
        )
      )
    )
    local.get $b
    local.get $a
    i32.sub
    local.set $cnt
    local.get $cnt
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 0
        local.set $cnt
      )
    )
    local.get $cnt
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $xs
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.mul
    i32.add
    local.get $cnt
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
  )
  (func $__arr_push (param $xs i32) (param $x i32) (result i32)
    (local $n i32) (local $p i32)
    local.get $xs
    i32.load
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $xs
    i32.const 4
    i32.add
    local.get $n
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
    i32.const 4
    i32.add
    local.get $n
    i32.const 4
    i32.mul
    i32.add
    local.get $x
    i32.store
    local.get $p
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (result i32)
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
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (result i32)
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
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (result i32)
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
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (result i64)
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
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (result i64)
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
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (result i64)
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
            unreachable
          )
        )
      )
    )
    local.get $r
  )
  (global $__task_head (mut i32) (i32.const 0))
  (global $__task_tail (mut i32) (i32.const 0))
  (global $__task_suspended (mut i32) (i32.const 0))
  (func $__task_new (param $kind i32) (param $frame i32) (result i32)
    (local $t i32)
    i32.const 40
    call $__alloc
    local.set $t
    local.get $t
    local.get $kind
    i32.store offset=20
    local.get $t
    local.get $frame
    i32.store offset=16
    local.get $t
  )
  (func $__task_start (param $kind i32) (param $frame i32) (result i32)
    (local $t i32)
    local.get $kind
    local.get $frame
    call $__task_new
    local.tee $t
    call $__task_resume
    local.get $t
  )
  (func $__task_pending (param $t i32) (result i32)
    local.get $t
    i32.load
    i32.eqz
  )
  (func $__task_listen (param $t i32) (param $kind i32) (param $target i32) (param $index i32)
    (local $n i32)
    i32.const 16
    call $__alloc
    local.set $n
    local.get $n
    local.get $t
    i32.load offset=4
    i32.store
    local.get $n
    local.get $kind
    i32.store offset=4
    local.get $n
    local.get $target
    i32.store offset=8
    local.get $n
    local.get $index
    i32.store offset=12
    local.get $t
    local.get $n
    i32.store offset=4
  )
  (func $__task_wait (param $t i32) (param $w i32)
    local.get $t
    i32.const 0
    local.get $w
    i32.const 0
    call $__task_listen
  )
  (func $__task_settle_i32 (param $t i32) (param $v i32)
    local.get $t
    local.get $v
    i32.store offset=8
    local.get $t
    call $__task_wake
  )
  (func $__task_settle_i64 (param $t i32) (param $v i64)
    local.get $t
    local.get $v
    i64.store offset=8
    local.get $t
    call $__task_wake
  )
  (func $__task_settle_f64 (param $t i32) (param $v f64)
    local.get $t
    local.get $v
    f64.store offset=8
    local.get $t
    call $__task_wake
  )
  (func $__task_wake (param $t i32)
    (local $n i32) (local $m i32) (local $r i32) (local $k i32) (local $w i32)
    local.get $t
    i32.load
    (if
      (then
        return
      )
    )
    local.get $t
    i32.const 1
    i32.store
    local.get $t
    i32.load offset=4
    local.set $n
    local.get $t
    i32.const 0
    i32.store offset=4
    (block $brk
      (loop $cont
        local.get $n
        i32.eqz
        br_if $brk
        local.get $n
        i32.load
        local.set $m
        local.get $n
        local.get $r
        i32.store
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
        i32.eqz
        br_if $brk
        local.get $r
        i32.load offset=4
        local.set $k
        local.get $r
        i32.load offset=8
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
            i32.load
            i32.eqz
            (if
              (then
                local.get $w
                local.get $t
                i64.load offset=8
                i64.store offset=8
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
            i32.load offset=28
            i32.const 4
            i32.add
            local.get $r
            i32.load offset=12
            i32.const 4
            i32.mul
            i32.add
            local.get $t
            i32.load offset=8
            i32.store
            local.get $w
            local.get $w
            i32.load offset=32
            i32.const 1
            i32.sub
            i32.store offset=32
            local.get $w
            i32.load offset=32
            i32.eqz
            (if
              (then
                local.get $w
                local.get $w
                i32.load offset=28
                i32.store offset=8
                local.get $w
                call $__task_wake
              )
            )
          )
        )
        local.get $r
        i32.load
        local.set $r
        br $cont
      )
    )
  )
  (func $__task_enqueue (param $t i32)
    local.get $t
    i32.const 0
    i32.store offset=24
    global.get $__task_tail
    (if
      (then
        global.get $__task_tail
        local.get $t
        i32.store offset=24
      )
      (else
        local.get $t
        global.set $__task_head
      )
    )
    local.get $t
    global.set $__task_tail
  )
  (func $__task_drain
    (local $t i32)
    (block $brk
      (loop $cont
        global.get $__task_head
        local.tee $t
        i32.eqz
        br_if $brk
        local.get $t
        i32.load offset=24
        global.set $__task_head
        global.get $__task_head
        i32.eqz
        (if
          (then
            i32.const 0
            global.set $__task_tail
          )
        )
        local.get $t
        call $__task_resume
        br $cont
      )
    )
  )
  (func $__task_block_on (param $t i32) (result i32)
    (local $r i32)
    (block $brk
      (loop $cont
        local.get $t
        i32.load
        br_if $brk
        global.get $__task_head
        local.tee $r
        i32.eqz
        (if
          (then
            unreachable
          )
        )
        local.get $r
        i32.load offset=24
        global.set $__task_head
        global.get $__task_head
        i32.eqz
        (if
          (then
            i32.const 0
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
  (func $__task_resume (param $t i32)
    (local $k i32)
    local.get $t
    i32.load offset=20 ;; kind
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
)
```

----- RUN LOG -----
```logs
yield 1
done
```
