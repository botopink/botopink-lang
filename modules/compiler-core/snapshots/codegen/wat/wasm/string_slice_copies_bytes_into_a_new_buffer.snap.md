----- SOURCE CODE -- main.bp
```botopink
fn first3() -> string {
    val s = "hello";
    return s.slice(0, 3);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\05\00\00\00hello")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $first3 (result i32)
    (local $s i32)
    i32.const 256
    local.set $s
    local.get $s
    i32.const 0
    i32.const 3
    call $__str_cp_slice
    return
  )
  (func $__str_slice (param $src i32) (param $start i32) (param $end i32) (result i32)
    (local $newlen i32) (local $dst i32)
    local.get $end
    local.get $start
    i32.sub
    local.set $newlen
    ;; allocate 4 (length prefix) + newlen
    i32.const 4
    local.get $newlen
    i32.add
    call $__alloc
    local.set $dst
    ;; store length prefix
    local.get $dst
    local.get $newlen
    i32.store
    ;; copy bytes: dst+4 <- src+4+start
    local.get $dst
    i32.const 4
    i32.add
    local.get $src
    i32.const 4
    i32.add
    local.get $start
    i32.add
    local.get $newlen
    memory.copy
    local.get $dst
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
  (func $__str_cp_len (param $s i32) (result i32)
    (local $n i32) (local $i i32) (local $k i32)
    local.get $s
    i32.load
    local.set $n
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $s
        local.get $i
        i32.add
        i32.load8_u offset=4
        i32.const 192
        i32.and
        i32.const 128
        i32.ne
        (if
          (then
            local.get $k
            i32.const 1
            i32.add
            local.set $k
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $k
  )
  (func $__str_cp_off (param $s i32) (param $i i32) (result i32)
    (local $n i32) (local $p i32) (local $k i32)
    local.get $s
    i32.load
    local.set $n
    (block $brk
      (loop $cont
        local.get $p
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $s
        local.get $p
        i32.add
        i32.load8_u offset=4
        i32.const 192
        i32.and
        i32.const 128
        i32.ne
        (if
          (then
            local.get $k
            local.get $i
            i32.eq
            (if
              (then
                local.get $p
                return
              )
            )
            local.get $k
            i32.const 1
            i32.add
            local.set $k
          )
        )
        local.get $p
        i32.const 1
        i32.add
        local.set $p
        br $cont
      )
    )
    local.get $n
  )
  (func $__str_cp_slice (param $s i32) (param $a i32) (param $b i32) (result i32)
    (local $n i32)
    local.get $s
    call $__str_cp_len
    local.set $n
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $a
        local.get $n
        i32.add
        local.set $a
      )
    )
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 0
        local.set $a
      )
    )
    local.get $a
    local.get $n
    i32.gt_s
    (if
      (then
        local.get $n
        local.set $a
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $b
        local.get $n
        i32.add
        local.set $b
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 0
        local.set $b
      )
    )
    local.get $b
    local.get $n
    i32.gt_s
    (if
      (then
        local.get $n
        local.set $b
      )
    )
    local.get $b
    local.get $a
    i32.lt_s
    (if
      (then
        local.get $a
        local.set $b
      )
    )
    local.get $s
    local.get $s
    local.get $a
    call $__str_cp_off
    local.get $s
    local.get $b
    call $__str_cp_off
    call $__str_slice
  )
)
```

----- RUN LOG -----
```logs
```
