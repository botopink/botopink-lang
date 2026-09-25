----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element> { }
#[@use]
fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> @Component<Element, #(i32, fn(action: i32) -> i32)> {
    val push = { action -> f(base, action) };
    #(base, push);
}
#[@use]
fn LikeWidget() -> @Component<Element, Element> {
    val #(shown, push) = use optimistic(12, { c, a -> c + a });
    push(shown);
    Element();
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (table funcref (elem $__lambda0 $__lambda1))
  (data (i32.const 256) "\0a\00\00\00R\07Element\00")
  (global $__heap_ptr (mut i32) (i32.const 272))
  (func $optimistic (param $base i32) (param $f i32) (result i32)
    (local $__mem0 i32)
    (local $push i32)
    (local $__mem1 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
    local.get $f
    i32.store offset=4 ;; capture f
    local.get $__mem0
    local.get $base
    i32.store offset=8 ;; capture base
    local.get $__mem0
    local.set $push
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    local.get $base
    i32.store
    local.get $__mem1
    local.get $push
    i32.store offset=4
    local.get $__mem1
  )
  (func $LikeWidget (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $shown i32)
    (local $push i32)
    (local $__fnv0 i32)
    (local $__mem2 i32)
    i32.const 12
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 1
    i32.store
    local.get $__mem1
    call $optimistic
    local.set $__mem0
    local.get $__mem0
    i32.load
    local.set $shown
    local.get $__mem0
    i32.load offset=4
    local.set $push
    local.get $push
    local.set $__fnv0
    local.get $__fnv0
    local.get $shown
    local.get $__fnv0
    i32.load ;; table index
    call_indirect (param i32 i32) (result i32)
    drop
    global.get $__heap_ptr
    local.set $__mem2
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem2
    i32.const 260
    i32.store
    local.get $__mem2
    i32.const 4
    i32.add
  )
  (func $__lambda0 (param $__env i32) (param $action i32) (result i32)
    (local $f i32)
    (local $base i32)
    (local $__fnv0 i32)
    local.get $__env
    i32.load offset=4
    local.set $f
    local.get $__env
    i32.load offset=8
    local.set $base
    local.get $f
    local.set $__fnv0
    local.get $__fnv0
    local.get $base
    local.get $action
    local.get $__fnv0
    i32.load ;; table index
    call_indirect (param i32 i32 i32) (result i32)
  )
  (func $__lambda1 (param $__env i32) (param $c i32) (param $a i32) (result i32)
    local.get $c
    local.get $a
    i32.add
  )
)
```

----- RUN LOG -----
```logs
```
