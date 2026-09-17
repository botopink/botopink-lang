----- SOURCE CODE -- main.bp
```botopink
record R { a: i32, b: i32 }
fn pick(maybe: ?R) -> i32 {
    return maybe?.b;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $pick (param $maybe i32) (result i32)
    (local $__mem0 i32)
    local.get $maybe
    local.tee $__mem0
    i32.eqz
    (if (result i32)
      (then
        i32.const 0 ;; ?.b on null
      )
      (else
        local.get $__mem0
        i32.load offset=4 ;; ?.b
        call $__box_i32
      )
    )
    return
  )
  (func $__alloc (param $n i32) (result i32)
    (local $p i32)
    global.get $__heap_ptr
    local.set $p
    global.get $__heap_ptr
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    global.set $__heap_ptr
    local.get $p
  )
  (func $__box_i32 (param $v i32) (result i32)
    (local $p i32)
    i32.const 4
    call $__alloc
    local.set $p
    local.get $p
    local.get $v
    i32.store
    local.get $p
  )
)
```

----- RUN LOG -----
```logs
```
