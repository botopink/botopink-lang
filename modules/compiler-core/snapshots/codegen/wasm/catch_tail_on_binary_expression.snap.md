----- SOURCE CODE -- main.bp
```botopink
type CalcError(msg: string)
fn getA() -> Result<i32, CalcError> {
    throw CalcError(msg: "overflow");
}
fn compute() -> i32 {
    val r = getA() catch 0;
    return r;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $rec_CalcError (struct (field $f0 (mut (ref null $str)))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $box_i32 (struct (field $v i32)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $getA (result (ref null $result))
    (local $__mem0 i32)
    i32.const 1
    global.get $__s0
    struct.new $rec_CalcError
    struct.new $result
    return
  )
  (func $compute (result i32)
    (local $_try0 i32)
    (local $r i32)
    (local $__gc0 (ref null $result))
    call $getA
    local.set $__gc0
    local.get $__gc0
    struct.get $result $tag ;; Result tag (0 = Ok, non-zero = Error)
    (if (result i32)
      (then
    i32.const 0
      )
      (else
    local.get $__gc0
    struct.get $result $payload ;; Ok payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
      )
    )
    local.set $r
    local.get $r
    return
  )
  (data $__d0 "overflow")
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
