----- SOURCE CODE -- main.bp
```botopink
fn fetch(x: i32) -> @Task<i32> {
    return x;
}
fn loadTwice(x: i32) -> @Task<i32> {
    val a = await fetch(x);
    return a + a;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; @Task — a state machine (decision 392)
  (func $fetch (param $x i32) (result i32)
    (local $__fr i32)
    i32.const 16 ;; the frame: the resume index, then every local
    call $__alloc
    local.set $__fr
    local.get $__fr
    local.get $x
    i32.store offset=8
    i32.const 0 ;; fetch__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $fetch__body (param $__task i32) (result i32)
    (local $x i32)
    (local $__frame i32)
    (local $__seek i32)
    (local $__state i32)
    local.get $__task
    i32.load offset=16
    local.set $__frame
    local.get $__frame
    i32.load offset=8
    local.set $x
    local.get $__frame
    i32.load ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $x
    return
  )
  (func $fetch__step (param $__task i32)
    (local $__v i32)
    local.get $__task
    call $fetch__body
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
  ;; @Task — a state machine (decision 392)
  (func $loadTwice (param $x i32) (result i32)
    (local $__fr i32)
    i32.const 32 ;; the frame: the resume index, then every local
    call $__alloc
    local.set $__fr
    local.get $__fr
    local.get $x
    i32.store offset=8
    i32.const 1 ;; loadTwice__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $loadTwice__body (param $__task i32) (result i32)
    (local $x i32)
    (local $a i32)
    (local $__frame i32)
    (local $__seek i32)
    (local $__state i32)
    (local $__aw1 i32)
    local.get $__task
    i32.load offset=16
    local.set $__frame
    local.get $__frame
    i32.load offset=8
    local.set $x
    local.get $__frame
    i32.load offset=16
    local.set $a
    local.get $__frame
    i32.load offset=24
    local.set $__aw1
    local.get $__frame
    i32.load ;; the resume index
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
    (block $__aw1
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
    br $__aw1 ;; resumed here
      )
    )
    br $__aw1 ;; resuming past this await
      )
    )
    local.get $x
    call $fetch
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $x
    i32.store offset=8
    local.get $__frame
    local.get $a
    i32.store offset=16
    local.get $__frame
    local.get $__aw1
    i32.store offset=24
    local.get $__frame
    i32.const 1
    i32.store ;; the resume index
    i32.const 1
    global.set $__task_suspended
    i32.const 0
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    i32.load offset=8 ;; the settled value
    local.set $a
      )
    )
    local.get $a
    local.get $a
    call $__i32_add_chk
    return
  )
  (func $loadTwice__step (param $__task i32)
    (local $__v i32)
    local.get $__task
    call $loadTwice__body
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
    call $fetch__step
    return
      )
    )
    local.get $k
    i32.const 1
    i32.eq
    (if
      (then
    local.get $t
    call $loadTwice__step
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
```
