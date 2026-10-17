----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val answer = 42;
    val assert 42 = answer catch throw "not 42";
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
  (func $f (result i32)
    (local $answer i32)
    (local $__assert_0 i32)
    i32.const 42
    local.set $answer
    local.get $answer
    local.set $__assert_0
    local.get $__assert_0
    i32.const 42
    i32.eq
    i32.eqz
    (if
      (then
    global.get $__s0
    drop
    unreachable
      )
    )
    i32.const 0
  )
  (data $__d0 "not 42")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 6
    array.new_data $str $__d0
    global.set $__s0
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
