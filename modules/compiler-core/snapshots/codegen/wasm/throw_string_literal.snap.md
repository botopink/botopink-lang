----- SOURCE CODE -- main.bp
```botopink
fn fail() -> Result<void, string> {
    throw "something went wrong";
    return;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $box_i32 (struct (field $v i32)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $fail (result (ref null $result))
    i32.const 1
    global.get $__s0
    struct.new $result
    return
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  (data $__d0 "something went wrong")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 20
    array.new_data $str $__d0
    global.set $__s0
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
