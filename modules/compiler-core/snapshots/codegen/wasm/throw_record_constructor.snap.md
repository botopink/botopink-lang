----- SOURCE CODE -- main.bp
```botopink
type AppError(code: i32, msg: string)
fn validate(x: i32) {
    if (x < 0) {
        throw AppError(code: 400, msg: "negative");
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $rec_AppError (struct (field $f0 (mut i32)) (field $f1 (mut (ref null $str)))))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $validate (param $x i32) (result i32)
    (local $__mem0 i32)
    local.get $x
    i32.const 0
    i32.lt_s
    (if (result i32)
      (then
    i32.const 400
    global.get $__s0
    struct.new $rec_AppError
    drop
    unreachable
      )
      (else
        i32.const 0
      )
    )
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
