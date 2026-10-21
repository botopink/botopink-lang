----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val answer = 42;
    val assert 42 = answer catch throw "not 42";
    return;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $box_i32 (struct (field $v i32)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $f (result (ref null $result))
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
    i32.const 1
    global.get $__s0
    struct.new $result
    return
      )
    )
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
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
