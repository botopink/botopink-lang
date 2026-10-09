----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Renderable
fn state(initial: i32) -> @Component<i32> {
    return initial;
}
fn memo() -> @Component<i32> {
    return 0;
}
fn Counter() -> @Component<Element> {
    val {count, setCount} = use state(0);
    val doubled = use memo { -> return count * 2; };
    return Element();
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\0a\00\00\00R\07Element\00")
  (global $__heap_ptr (mut i32) (i32.const 272))
  (func $state (param $bpContextMap__ i32) (param $initial i32) (result i32)
    local.get $initial
    return
  )
  (func $memo (param $bpContextMap__ i32) (result i32)
    i32.const 0
    return
  )
  (func $Counter (param $bpContextMap__ i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $count i32)
    (local $setCount i32)
    (local $doubled i32)
    local.get $bpContextMap__
    i32.const 0
    call $state
    local.set $__mem0
    local.get $__mem0
    i32.load
    local.set $count
    local.get $__mem0
    i32.load offset=4
    local.set $setCount
    local.get $bpContextMap__
    call $memo
    local.set $doubled
    i32.const 4
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 260
    i32.store
    local.get $__mem1
    i32.const 4
    i32.add
    return
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
