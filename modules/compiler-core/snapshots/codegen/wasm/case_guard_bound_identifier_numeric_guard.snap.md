----- SOURCE CODE -- main.bp
```botopink
fn classify(n: i32) -> string {
    return case n {
        x if x > 0 -> "positive";
        0 -> "zero";
        _ -> "negative";
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $classify (param $n i32) (result (ref null $str))
    (local $x i32)
    (local $__case_0 i32)
    local.get $n
    local.set $__case_0
    local.get $__case_0
    local.set $x
    local.get $x
    i32.const 0
    i32.gt_s
    (if (result (ref null $str))
      (then
    global.get $__s0
      )
      (else
    local.get $__case_0
    i32.const 0
    i32.eq
    (if (result (ref null $str))
      (then
    global.get $__s1
      )
      (else
    global.get $__s2
      )
    )
      )
    )
    return
  )
  (data $__d0 "positive")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "zero")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "negative")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 8
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 4
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 8
    array.new_data $str $__d2
    global.set $__s2
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
