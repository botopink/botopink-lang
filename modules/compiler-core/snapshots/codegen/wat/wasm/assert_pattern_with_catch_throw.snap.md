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
  (data (i32.const 256) "\14\00\00\00R\06Person\02\04names\03agei")
  (data (i32.const 280) "\03\00\00\00ann")
  (data (i32.const 288) "\0d\00\00\00is not person")
  (global $__heap_ptr (mut i32) (i32.const 308))
  (func $f (result i32)
    (local $__mem0 i32)
    (local $r i32)
    (local $__assert_0 i32)
    (local $name i32)
    (local $age i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 280
    i32.store offset=4
    local.get $__mem0
    i32.const 30
    i32.store offset=8
    local.get $__mem0
    i32.const 4
    i32.add
    local.set $r
    local.get $r
    local.set $__assert_0
    local.get $__assert_0
    i32.const 256
    i32.ge_u
    local.get $__assert_0
    i32.const 4
    i32.sub
    local.get $__assert_0
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 260
    i32.eq
    i32.and
    i32.eqz
    (if
      (then
    i32.const 288
    drop
    unreachable
      )
    )
    local.get $__assert_0
    i32.load ;; .name
    local.set $name
    local.get $__assert_0
    i32.load offset=4 ;; .age
    local.set $age
    i32.const 0
  )
)
```

----- RUN LOG -----
```logs
```
