----- SOURCE CODE -- main.bp
```botopink
val Shape = type {
    Circle(r: i32),
    Square(s: i32),
}
fn big(sh: Shape) -> string {
    return case sh {
        Circle(r) if r > 10 -> "big circle";
        _ -> "other";
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $var_Shape_Circle (struct (field $f0 (mut i32))))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $big (param $sh anyref) (result (ref null $str))
    (local $r i32)
    (local $__case_0 anyref)
    local.get $sh
    local.set $__case_0
    local.get $__case_0
    ref.test (ref null $var_Shape_Circle)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_Shape_Circle)
    struct.get $var_Shape_Circle $f0
    local.set $r
    local.get $r
    i32.const 10
    i32.gt_s
    (if (result (ref null $str))
      (then
    global.get $__s0
      )
      (else
    global.get $__s1
      )
    )
      )
      (else
    global.get $__s1
      )
    )
    return
  )
  (data $__d0 "big circle")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "other")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 10
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 5
    array.new_data $str $__d1
    global.set $__s1
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
