----- SOURCE CODE -- main.bp
```botopink
type IoError(path: string)
fn step1() -> Result<i32, IoError> {
    throw IoError(path: "/data");
}
fn step2(x: i32) -> Result<i32, IoError> {
    throw IoError(path: "/out");
}
fn pipeline() -> Result<i32, IoError> {
    val a = try step1();
    val b = try step2(a);
    return b;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $rec_IoError (struct (field $f0 (mut (ref null $str)))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $box_i32 (struct (field $v i32)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $step1 (result (ref null $result))
    (local $__mem0 i32)
    i32.const 1
    global.get $__s0
    struct.new $rec_IoError
    struct.new $result
    return
  )
  (func $step2 (param $x i32) (result (ref null $result))
    (local $__mem0 i32)
    i32.const 1
    global.get $__s1
    struct.new $rec_IoError
    struct.new $result
    return
  )
  (func $pipeline (result (ref null $result))
    (local $_try0 i32)
    (local $_try1 i32)
    (local $a i32)
    (local $b i32)
    (local $__gc0 (ref null $result))
    (local $__gc1 (ref null $result))
    call $step1
    local.set $__gc0
    local.get $__gc0
    struct.get $result $tag
    (if
      (then
    local.get $__gc0
    return ;; propagate Error
      )
    )
    local.get $__gc0
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $a
    local.get $a
    call $step2
    local.set $__gc1
    local.get $__gc1
    struct.get $result $tag
    (if
      (then
    local.get $__gc1
    return ;; propagate Error
      )
    )
    local.get $__gc1
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $b
    i32.const 0
    local.get $b
    struct.new $box_i32
    struct.new $result
    return
  )
  (data $__d0 "/data")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "/out")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 5
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 4
    array.new_data $str $__d1
    global.set $__s1
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
