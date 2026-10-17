----- SOURCE CODE -- main.bp
```botopink
fn range(a: i32, b: i32) -> @Iterator<i32> {
    yield a;
    yield b;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_i32 (array (mut i32)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; @Iterator — eager lowering
  (func $range (param $a i32) (param $b i32) (result (ref null $arr_i32))
    (local $__yield_fn (ref null $arr_i32))
    i32.const 0
    array.new_default $arr_i32
    local.set $__yield_fn
    local.get $__yield_fn
    local.get $a
    call $__arr_push_i32
    local.set $__yield_fn
    local.get $__yield_fn
    local.get $b
    call $__arr_push_i32
    local.set $__yield_fn
    local.get $__yield_fn ;; everything the body yielded
  )
  (func $__arr_push_i32 (param $xs (ref null $arr_i32)) (param $x i32) (result (ref null $arr_i32))
    (local $n i32)
    (local $r (ref null $arr_i32))
    local.get $xs
    array.len
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    array.new_default $arr_i32
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $n
    array.copy $arr_i32 $arr_i32
    local.get $r
    local.get $n
    local.get $x
    array.set $arr_i32
    local.get $r
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
