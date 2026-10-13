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
  (global $__heap_ptr (mut i32) (i32.const 288))
  (func $first3 (result i32)
    (local $s i32)
    i32.const 256
    local.set $s
    local.get $s
    i32.const 0
    i32.const 3
    call $__std_text_slice
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
  (global $__std_sp (mut i32) (i32.const 288))
  (func $__std_sp_check (param $sp i32) (result i32)
    local.get $sp
    i32.const 272
    i32.lt_s
    (if
      (then unreachable)
    )
    local.get $sp
  )
  ;; __std_f4 — from std_wasm.wasm (sha256 b4b6f06748d6)
  ;; __std_f263 — from std_wasm.wasm (sha256 7774ddf64350)
  ;; __std_f265 — from std_wasm.wasm (sha256 5ac39cdc3016)
  ;; __std_f266 — from std_wasm.wasm (sha256 cda2fb2bf3e4)
  ;; std:text.slice — from std_wasm.wasm (sha256 49c89fe83b13)
)
```

----- RUN LOG -----
```logs
```
