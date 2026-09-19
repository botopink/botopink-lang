----- SOURCE CODE -- main.bp
```botopink
type Person(name: string, age: i32)
fn f() {
    val r = Person(name: "ann", age: 30);
    val assert Person(name, age) = r catch throw "is not person";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\03\00\00\00ann")
  (global $__heap_ptr (mut i32) (i32.const 264))
  (func $f (result i32)
    (local $__mem0 i32)
    (local $r i32)
    (local $__assert_0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 256
    i32.store
    local.get $__mem0
    i32.const 30
    i32.store offset=4
    local.get $__mem0
    local.set $r
    local.get $r
    local.set $__assert_0
    i32.const 0
  )
)
```

----- RUN LOG -----
```logs
```
