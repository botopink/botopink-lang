----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val list: i32[] = [];
    val assert [] = list catch throw "not empty";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\09\00\00\00not empty")
  (global $__heap_ptr (mut i32) (i32.const 272))
  (func $f (result i32)
    (local $__mem0 i32)
    (local $list i32)
    (local $__assert_0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
    local.set $list
    local.get $list
    local.set $__assert_0
    local.get $__assert_0
    i32.load ;; element count
    i32.const 0
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 256
    drop
    unreachable
      )
    )
    i32.const 0
  )
)
```

----- RUN LOG -----
```logs
```
