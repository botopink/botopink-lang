----- SOURCE CODE -- main.bp
```botopink
type List(tag: i32) {
    fn map(items: i32[], f: fn(item: i32) -> i32) -> i32[] {
        return items.map(f);
    }
}
type Pipeline(
    items: i32[]) {
    fn run(self: Self, f: fn(item: i32) -> i32) -> i32[] {
        return List.map(self.items, f);
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (table funcref (elem))
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $List_map (param $items i32) (param $f i32) (result i32)
    (local $__iter1 i32)
    (local $__idx1 i32)
    (local $__len1 i32)
    (local $__acc1 i32)
    (local $__out1 i32)
    (local $__hof0_0 i32)
    (local $__fnv2 i32)
    local.get $items
    local.set $__iter1
    local.get $__iter1
    i32.load ;; element count
    local.set $__len1
    i32.const 0
    local.set $__idx1
    local.get $__len1
    call $__arr_new
    local.set $__out1
    i32.const 0
    local.set $__acc1
    (block $__break
      (loop $__continue
        local.get $__idx1
        local.get $__len1
        i32.ge_s
        br_if $__break
        local.get $__iter1
        local.get $__idx1
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $__hof0_0
    local.get $__out1
    local.get $__idx1
    i32.const 4
    i32.mul
    i32.add
    local.get $f
    local.set $__fnv2
    local.get $__fnv2
    local.get $__hof0_0
    local.get $__fnv2
    i32.load ;; table index
    call_indirect (param i32 i32) (result i32)
    i32.store offset=4
        local.get $__idx1
        i32.const 1
        i32.add
        local.set $__idx1
        br $__continue
      )
    )
    local.get $__out1
    return
  )
  (func $Pipeline_run (param $self i32) (param $f i32) (result i32)
    local.get $self
    i32.load ;; .items
    local.get $f
    call $List_map
    return
  )
  (func $__alloc (param $n i32) (result i32)
    (local $p i32)
    global.get $__heap_ptr
    local.set $p
    global.get $__heap_ptr
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    global.set $__heap_ptr
    local.get $p
  )
  (func $__arr_new (param $n i32) (result i32)
    (local $p i32)
    local.get $n
    i32.const 1
    i32.add
    i32.const 4
    i32.mul
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
    local.get $p
  )
)
```

----- RUN LOG -----
```logs
```
