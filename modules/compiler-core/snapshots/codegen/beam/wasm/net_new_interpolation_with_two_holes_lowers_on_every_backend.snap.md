----- SOURCE CODE -- main.bp
```botopink
fn label(a: string, b: string) -> string {
    return "${a}-${b}";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\00\00\00\00")
  (data (i32.const 260) "\01\00\00\00-")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $label (param $a i32) (param $b i32) (result i32)
    i32.const 256
    local.get $a
    call $__str_concat
    i32.const 260
    call $__str_concat
    local.get $b
    call $__str_concat
    return
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
)
```

----- RUN LOG -----
```logs
```
