----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val greeting = "hello";
    val assert "hello" = greeting catch throw "not hello";
    return;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (data (i32.const 11696) "\05\00\00\00hello")
  (data (i32.const 11708) "\09\00\00\00not hello")
  (func $f (result i32)
    (local $greeting i32)
    (local $__assert_0 i32)
    (local $_res0 i32)
    (local $_res1 i32)
    i32.const 11696
    local.set $greeting
    local.get $greeting
    local.set $__assert_0
    local.get $__assert_0
    i32.const 11696
    call $__str_eq
    i32.eqz
    (if
      (then
    i32.const 8
    call $__alloc
    local.set $_res0
    local.get $_res0
    i32.const 1
    i32.store ;; Result tag (Error)
    local.get $_res0
    i32.const 11708
    i32.store offset=4 ;; payload
    local.get $_res0
    return
      )
    )
    i32.const 8
    call $__alloc
    local.set $_res1
    local.get $_res1
    i32.const 0
    i32.store ;; Result tag (Ok)
    local.get $_res1
    i32.const 0
    i32.store offset=4 ;; payload
    local.get $_res1
    return
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
  (start $__bp_reserve)
  (func $__bp_reserve
    global.get $__heap_ptr
    i32.const 11724
    i32.lt_u
    (if
      (then
      i32.const 11724
      global.set $__heap_ptr
      )
    )
  )
)
```

----- RUN LOG -----
```logs
```
