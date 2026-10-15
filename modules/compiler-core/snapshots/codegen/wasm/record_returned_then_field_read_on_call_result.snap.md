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
  (rec
    (type $str (array (mut i8)))
    (type $rec_Span (struct (field $f0 (mut i32)) (field $f1 (mut i32)) (field $f2 (mut i32))))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $span (result (ref null $rec_Span))
    (local $__mem0 i32)
    i32.const 4
    i32.const 9
    i32.const 2
    struct.new $rec_Span
    return
  )
  (func $lineNo (result i32)
    call $span
    struct.get $rec_Span $f2
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
