----- SOURCE CODE -- main.bp
```botopink
fn node() -> string { return "n"; }
fn box(children: Children) -> string { return "x"; }
val many = box([node(), node()]);
val one = box(node());
val txt = box("hi");
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (start $__bp_reserve)
  (data $__bp_seg0 "\01\00\00\00n")
  (data $__bp_seg1 "\01\00\00\00x")
  (data $__bp_seg2 "\02\00\00\00hi")
  (func $node (result i32)
    i32.const 11680
    return
  )
  (func $box (param $children i32) (result i32)
    i32.const 11688
    return
  )
  (global $many (mut i32) (i32.const 0))
  (global $one (mut i32) (i32.const 0))
  (global $txt (mut i32) (i32.const 0))
  (func $__init_globals
    (local $__mem0 i32)
    i32.const 12
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 2
    i32.store
    local.get $__mem0
    call $node
    i32.store offset=4
    local.get $__mem0
    call $node
    i32.store offset=8
    local.get $__mem0
    call $box
    global.set $many
    call $node
    call $box
    global.set $one
    i32.const 11696
    call $box
    global.set $txt
  )
  (func $__bp_reserve
    memory.size
    i32.const 1
    i32.lt_u
    (if
      (then
      i32.const 1
      memory.size
      i32.sub
      memory.grow
      drop
      )
    )
    i32.const 11680
    i32.const 0
    i32.const 5
    memory.init $__bp_seg0
    data.drop $__bp_seg0
    i32.const 11688
    i32.const 0
    i32.const 5
    memory.init $__bp_seg1
    data.drop $__bp_seg1
    i32.const 11696
    i32.const 0
    i32.const 6
    memory.init $__bp_seg2
    data.drop $__bp_seg2
    global.get $__heap_ptr
    i32.const 11704
    i32.lt_u
    (if
      (then
      i32.const 11704
      global.set $__heap_ptr
      )
    )
    call $__init_globals
  )
)
```

----- RUN LOG -----
```logs
```
