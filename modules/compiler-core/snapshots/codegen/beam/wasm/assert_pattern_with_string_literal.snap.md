----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val greeting = "hello";
    val assert "hello" = greeting catch throw "not hello";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\05\00\00\00hello")
  (data (i32.const 268) "\09\00\00\00not hello")
  (global $__heap_ptr (mut i32) (i32.const 284))
  (func $f (result i32)
    (local $greeting i32)
    (local $__assert_0 i32)
    i32.const 256
    local.set $greeting
    local.get $greeting
    local.set $__assert_0
    local.get $__assert_0
    i32.const 256
    call $__str_eq
    i32.eqz
    (if
      (then
    i32.const 268
    drop
    unreachable
      )
    )
    i32.const 0
  )
  (func $__str_eq (param $a i32) (param $b i32) (result i32)
    (local $i i32) (local $alen i32)
    local.get $a
    i32.load
    local.set $alen
    local.get $alen
    local.get $b
    i32.load
    i32.ne
    (if
      (then i32.const 0 return)
    )
    (block $done
      (loop $cmp
        local.get $i
        local.get $alen
        i32.ge_u
        br_if $done
        local.get $a
        local.get $i
        i32.add
        i32.load8_u offset=4
        local.get $b
        local.get $i
        i32.add
        i32.load8_u offset=4
        i32.ne
        (if
          (then i32.const 0 return)
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cmp
      )
    )
    i32.const 1
  )
)
```

----- RUN LOG -----
```logs
```
