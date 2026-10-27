----- SOURCE CODE -- main.bp
```botopink
type Person(name: string, age: i32)
fn f() -> Result<void, string> {
    val r = Person(name: "ann", age: 30);
    val assert Person(name, age) = r catch throw "is not person";
    return;
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
  (data (i32.const 11728) "\0d\00\00\00is not person")
  (func $f (result i32)
    (local $__mem0 i32)
    (local $r i32)
    (local $__assert_0 i32)
    (local $_res0 i32)
    (local $name i32)
    (local $age i32)
    (local $_res1 i32)
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
    i32.const 8
    call $__alloc
    local.set $_res0
    local.get $_res0
    i32.const 1
    i32.store ;; Result tag (Error)
    local.get $_res0
    i32.const 11728
    i32.store offset=4 ;; payload
    local.get $_res0
    return
      )
    )
    local.get $__assert_0
    i32.load ;; .name
    local.set $name
    local.get $__assert_0
    i32.load offset=4 ;; .age
    local.set $age
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
  (start $__bp_reserve)
  (func $__bp_reserve
    global.get $__heap_ptr
    i32.const 11748
    i32.lt_u
    (if
      (then
      i32.const 11748
      global.set $__heap_ptr
      )
    )
  )
)
```

----- RUN LOG -----
```logs
```
