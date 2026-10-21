----- SOURCE CODE -- main.bp
```botopink
fn process(f: fn(x: i32) -> i32) -> i32 {
    return f(5);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $box_i32 (struct (field $v i32)))
    (type $closure (sub (struct (field $idx i32) (field $mark i32))))
  )
  (memory (export "memory") 1)
  (table funcref (elem))
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $process (param $f (ref null $closure)) (result i32)
    (local $__fnv0 (ref null $closure))
    local.get $f
    local.set $__fnv0
    local.get $__fnv0
    i32.const 5
    struct.new $box_i32
    local.get $__fnv0
    struct.get $closure $idx ;; table index
    call_indirect (param (ref null $closure) anyref) (result anyref)
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
