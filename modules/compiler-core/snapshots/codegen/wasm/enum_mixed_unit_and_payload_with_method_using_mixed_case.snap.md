----- SOURCE CODE -- main.bp
```botopink
val Maybe = type {
    Nothing,
    Just(value: string),
    fn check(m: Self) -> string {
        return case m {
            Nothing -> "nothing";
            Just(value) -> "just";
        };
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $var_Maybe_Nothing (struct))
    (type $var_Maybe_Just (struct (field $f0 (mut (ref null $str)))))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $Maybe_check (param $m anyref) (result (ref null $str))
    (local $value (ref null $str))
    (local $__case_0 anyref)
    local.get $m
    local.set $__case_0
    local.get $__case_0
    ref.test (ref null $var_Maybe_Nothing)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    global.get $__s0
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_Maybe_Just)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_Maybe_Just)
    struct.get $var_Maybe_Just $f0
    local.set $value
    global.get $__s1
      )
      (else
    ref.null $str
      )
    )
      )
    )
    return
  )
  (data $__d0 "nothing")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "just")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 7
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
