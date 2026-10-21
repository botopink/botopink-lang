----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
fn make() -> Point {
    return Point(x: 3, y: 4);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $rec_Point (struct (field $f0 (mut i32)) (field $f1 (mut i32))))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $make (result (ref null $rec_Point))
    (local $__mem0 i32)
    i32.const 3
    i32.const 4
    struct.new $rec_Point
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
