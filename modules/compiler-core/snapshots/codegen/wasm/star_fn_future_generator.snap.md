----- SOURCE CODE -- main.bp
```botopink
fn stream() -> @Stream<@Result<i32, string>> {
    yield 1;
    yield 2;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_any (array (mut anyref)))
    (type $box_i32 (struct (field $v i32)))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; @Stream — eager lowering
  (func $stream (result (ref null $arr_any))
    (local $__yield_fn (ref null $arr_any))
    i32.const 0
    array.new_default $arr_any
    local.set $__yield_fn
    local.get $__yield_fn
    i32.const 0
    i32.const 1
    struct.new $box_i32
    struct.new $result
    call $__arr_push_any
    local.set $__yield_fn
    local.get $__yield_fn
    i32.const 0
    i32.const 2
    struct.new $box_i32
    struct.new $result
    call $__arr_push_any
    local.set $__yield_fn
    local.get $__yield_fn ;; everything the body yielded
  )
  (func $__arr_push_any (param $xs (ref null $arr_any)) (param $x anyref) (result (ref null $arr_any))
    (local $n i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $n
    array.copy $arr_any $arr_any
    local.get $r
    local.get $n
    local.get $x
    array.set $arr_any
    local.get $r
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
