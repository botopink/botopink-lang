----- SOURCE CODE -- main.bp
```botopink
val list1 = [1, ..[]];
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_i32 (array (mut i32)))
  )
  (memory (export "memory") 1)
  (start $__init_globals)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $list1 (mut (ref null $arr_i32)) (ref.null $arr_i32))
  (func $__init_globals
    (local $__mem0 i32)
    i32.const 1
    array.new_fixed $arr_i32 1
    array.new_fixed $arr_i32 0
    call $__arr_concat_i32
    global.set $list1
  )
  (func $__arr_concat_i32 (param $xs (ref null $arr_i32)) (param $ys (ref null $arr_i32)) (result (ref null $arr_i32))
    (local $la i32)
    (local $lb i32)
    (local $r (ref null $arr_i32))
    local.get $xs
    array.len
    local.set $la
    local.get $ys
    array.len
    local.set $lb
    local.get $la
    local.get $lb
    i32.add
    array.new_default $arr_i32
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $la
    array.copy $arr_i32 $arr_i32
    local.get $r
    local.get $la
    local.get $ys
    i32.const 0
    local.get $lb
    array.copy $arr_i32 $arr_i32
    local.get $r
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
