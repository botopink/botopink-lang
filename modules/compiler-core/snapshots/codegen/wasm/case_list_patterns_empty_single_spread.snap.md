----- SOURCE CODE -- main.bp
```botopink
fn describe() -> string {
    val items = ["a", "b", "c"];
    return case items {
        [] -> "empty";
        [x] -> "one";
        [first, ..rest] -> "many";
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\01\00\00\00a")
  (data (i32.const 264) "\01\00\00\00b")
  (data (i32.const 272) "\01\00\00\00c")
  (data (i32.const 280) "\05\00\00\00empty")
  (data (i32.const 292) "\03\00\00\00one")
  (data (i32.const 300) "\04\00\00\00many")
  (global $__heap_ptr (mut i32) (i32.const 352))
  (func $describe (result i32)
    (local $__mem0 i32)
    (local $items i32)
    (local $x i32)
    (local $first i32)
    (local $rest i32)
    (local $__case_0 i32)
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 3
    i32.store
    local.get $__mem0
    i32.const 256
    i32.store offset=4
    local.get $__mem0
    i32.const 264
    i32.store offset=8
    local.get $__mem0
    i32.const 272
    i32.store offset=12
    local.get $__mem0
    local.set $items
    local.get $items
    local.set $__case_0
    local.get $__case_0
    i32.load ;; element count
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    i32.const 280
      )
      (else
    local.get $__case_0
    i32.load ;; element count
    i32.const 1
    i32.eq
    (if (result i32)
      (then
    local.get $__case_0
    i32.load offset=4
    local.set $x
    i32.const 292
      )
      (else
    local.get $__case_0
    i32.load ;; element count
    i32.const 1
    i32.ge_u
    (if (result i32)
      (then
    local.get $__case_0
    i32.load offset=4
    local.set $first
    local.get $__case_0
    i32.const 1
    i32.const 2147483647
    call $__std_array_slice
    local.set $rest
    i32.const 300
      )
      (else
    i32.const 0
      )
    )
      )
    )
      )
    )
    return
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
  ;; std-wasm (decision 440): its functions, transpiled from std_wasm.wasm
  (global $__std_sp (mut i32) (i32.const 352))
  (func $__std_sp_check (param $sp i32) (result i32)
    local.get $sp
    i32.const 312
    i32.lt_s
    (if
      (then unreachable)
    )
    local.get $sp
  )
  ;; __std_f416 — from std_wasm.wasm (sha256 d13a98c08300)
  ;; __std_f417 — from std_wasm.wasm (sha256 eaf687f8b1c6)
  ;; __std_f418 — from std_wasm.wasm (sha256 0314fe5f477f)
  ;; __std_f419 — from std_wasm.wasm (sha256 d0f3edd6b423)
  ;; std:array.slice — from std_wasm.wasm (sha256 0bd2f83307bd)
)
```

----- RUN LOG -----
```logs
```
