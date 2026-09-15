----- SOURCE CODE -- main.bp
```botopink
record Span { start: i32, end: i32, line: i32 }
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
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $span (result i32)
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 4
    i32.store
    local.get $__mem0
    i32.const 9
    i32.store offset=4
    local.get $__mem0
    i32.const 2
    i32.store offset=8
    local.get $__mem0
    return
  )
  (func $lineNo (result i32)
    call $span
    i32.load offset=8 ;; .line
    return
  )
)
```

----- RUN LOG -----
```logs
```
