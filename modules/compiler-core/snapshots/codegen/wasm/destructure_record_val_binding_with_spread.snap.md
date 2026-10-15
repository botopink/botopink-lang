----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32, z: i32)
fn describe(p: Point) -> i32 {
    val { x, .. } = p;
    return x;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $rec_Point (struct (field $f0 (mut i32)) (field $f1 (mut i32)) (field $f2 (mut i32))))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $describe (param $p (ref null $rec_Point)) (result i32)
    (local $__mem0 i32)
    (local $x i32)
    (local $__gc0 (ref null $rec_Point))
    local.get $p
    local.set $__gc0
    local.get $__gc0
    struct.get $rec_Point $f0
    local.set $x
    local.get $x
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
