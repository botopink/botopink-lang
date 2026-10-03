----- SOURCE CODE -- main.bp
```botopink
type Span(start: i32, end: i32, line: i32)
fn span() -> Span {
    return Span(start: 4, end: 9, line: 2);
}
fn lineNo() -> i32 {
    return span().line;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\19\00\00\00R\04Span\03\05starti\03endi\04linei")
  (global $__heap_ptr (mut i32) (i32.const 288))
  (func $span (result i32)
    (local $__mem0 i32)
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 4
    i32.store offset=4
    local.get $__mem0
    i32.const 9
    i32.store offset=8
    local.get $__mem0
    i32.const 2
    i32.store offset=12
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $lineNo (result i32)
    call $span
    i32.load offset=8 ;; .line
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
)
```

----- RUN LOG -----
```logs
```
