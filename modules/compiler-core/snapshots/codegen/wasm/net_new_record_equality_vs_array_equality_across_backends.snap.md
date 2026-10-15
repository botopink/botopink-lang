----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
fn recordEq() -> bool {
    val a = Point(x: 1, y: 2);
    val b = Point(x: 1, y: 2);
    return a == b;
}
fn arrayEq() -> bool {
    val xs = [1, 2];
    val ys = [1, 2];
    return xs == ys;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $rec_Point (struct (field $f0 (mut i32)) (field $f1 (mut i32))))
    (type $arr_i32 (array (mut i32)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $recordEq (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $a (ref null $rec_Point))
    (local $b (ref null $rec_Point))
    i32.const 1
    i32.const 2
    struct.new $rec_Point
    local.set $a
    i32.const 1
    i32.const 2
    struct.new $rec_Point
    local.set $b
    local.get $a
    local.get $b
    call $__eq_Point
    return
  )
  (func $arrayEq (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $xs (ref null $arr_i32))
    (local $ys (ref null $arr_i32))
    i32.const 1
    i32.const 2
    array.new_fixed $arr_i32 2
    local.set $xs
    i32.const 1
    i32.const 2
    array.new_fixed $arr_i32 2
    local.set $ys
    local.get $xs
    local.get $ys
    call $__eq_Array_i32
    return
  )
  (func $__eq_Point (param $a (ref null $rec_Point)) (param $b (ref null $rec_Point)) (result i32)
    local.get $a
    struct.get $rec_Point $f0
    local.get $b
    struct.get $rec_Point $f0
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    struct.get $rec_Point $f1
    local.get $b
    struct.get $rec_Point $f1
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    i32.const 1
  )
  (func $__eq_Array_i32 (param $a (ref null $arr_i32)) (param $b (ref null $arr_i32)) (result i32)
    (local $n i32)
    (local $i i32)
    local.get $a
    array.len
    local.get $b
    array.len
    i32.ne
    (if
      (then i32.const 0 return)
    )
    local.get $a
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $a
    local.get $i
    array.get $arr_i32
    local.get $b
    local.get $i
    array.get $arr_i32
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    i32.const 1
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
