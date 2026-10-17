----- SOURCE CODE -- main.bp
```botopink
type R(a: i32, b: i32)
fn pick(maybe: ?R) -> ?i32 {
    return maybe?.b;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $rec_R (struct (field $f0 (mut i32)) (field $f1 (mut i32))))
    (type $box_i32 (struct (field $v i32)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $pick (param $maybe (ref null $rec_R)) (result anyref)
    (local $__mem0 i32)
    (local $__gc0 (ref null $rec_R))
    local.get $maybe
    local.tee $__gc0
    ref.is_null
    (if (result anyref)
      (then
    ref.null any
      )
      (else
    local.get $__gc0
    struct.get $rec_R $f1
    struct.new $box_i32
      )
    )
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
