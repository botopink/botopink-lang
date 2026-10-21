----- SOURCE CODE -- main.bp
```botopink
type AppError(code: i32, msg: string)
fn validate(x: i32) -> Result<void, AppError> {
    if (x < 0) {
        throw AppError(code: 400, msg: "negative");
    };
    return;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $rec_AppError (struct (field $f0 (mut i32)) (field $f1 (mut (ref null $str)))))
    (type $box_i32 (struct (field $v i32)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $validate (param $x i32) (result (ref null $result))
    (local $__mem0 i32)
    local.get $x
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    i32.const 400
    global.get $__s0
    struct.new $rec_AppError
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  (data $__d0 "negative")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 8
    array.new_data $str $__d0
    global.set $__s0
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
