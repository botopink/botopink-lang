----- SOURCE CODE -- main.bp
```botopink
type Person(name: string, age: i32)
fn f() -> void {
    val r = Person(name: "ann", age: 30);
    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (data (i32.const 11696) "\14\00\00\00R\06Person\02\04names\03agei")
  (data (i32.const 11720) "\03\00\00\00ann")
  (data (i32.const 11728) "\03\00\00\00bob")
  (func $f (result i32)
    (local $__mem0 i32)
    (local $r i32)
    (local $__assert_0 i32)
    (local $__mem1 i32)
    (local $name i32)
    (local $age i32)
    i32.const 12
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 11700
    i32.store
    local.get $__mem0
    i32.const 11720
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
    i32.const 11700
    i32.eq
    i32.and
    i32.eqz
    (if
      (then
    i32.const 12
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 11700
    i32.store
    local.get $__mem1
    i32.const 11728
    i32.store offset=4
    local.get $__mem1
    i32.const 12
    i32.store offset=8
    local.get $__mem1
    i32.const 4
    i32.add
    local.set $__assert_0
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
  (start $__bp_reserve)
  (func $__bp_reserve
    global.get $__heap_ptr
    i32.const 11736
    i32.lt_u
    (if
      (then
      i32.const 11736
      global.set $__heap_ptr
      )
    )
  )
)
```

----- RUN LOG -----
```logs
```
