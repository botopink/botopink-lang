----- SOURCE CODE -- main.bp
```botopink
type Person(name: string, age: i32)
fn f() {
    val r = Person(name: "ann", age: 30);
    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\14\00\00\00R\06Person\02\04names\03agei")
  (data (i32.const 280) "\03\00\00\00ann")
  (data (i32.const 288) "\03\00\00\00bob")
  (global $__heap_ptr (mut i32) (i32.const 296))
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
    i32.const 12
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 260
    i32.store
    local.get $__mem1
    i32.const 288
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
  (func $__alloc (param $n i32) (result i32)
    (local $p i32) (local $e i32)
    global.get $__heap_ptr
    local.set $p
    local.get $p
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    local.set $e
    local.get $e
    local.get $p
    i32.lt_u
    (if
      (then
        unreachable
      )
    )
    local.get $e
    memory.size
    i32.const 16
    i32.shl
    i32.gt_u
    (if
      (then
        local.get $e
        i32.const 65535
        i32.add
        i32.const 16
        i32.shr_u
        memory.size
        i32.sub
        memory.grow
        i32.const -1
        i32.eq
        (if
          (then
            unreachable
          )
        )
      )
    )
    local.get $e
    global.set $__heap_ptr
    local.get $p
  )
)
```

----- RUN LOG -----
```logs
```
