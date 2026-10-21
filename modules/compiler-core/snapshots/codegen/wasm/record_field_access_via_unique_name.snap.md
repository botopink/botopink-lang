----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
fn first(p: Point) -> i32 {
    return p.x;
}
fn second(p: Point) -> i32 {
    return p.y;
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
  (func $first (param $p (ref null $rec_Point)) (result i32)
    local.get $p
    struct.get $rec_Point $f0
    return
  )
  (func $second (param $p (ref null $rec_Point)) (result i32)
    local.get $p
    struct.get $rec_Point $f1
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
