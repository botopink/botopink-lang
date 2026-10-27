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
  (data (i32.const 11696) "\01\00\00\00n")
  (data (i32.const 11704) "\01\00\00\00x")
  (data (i32.const 11712) "\02\00\00\00hi")
  (func $node (result i32)
    i32.const 11696
    return
  )
  (func $box (param $children i32) (result i32)
    i32.const 11704
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
    i32.const 11712
    call $box
    global.set $txt
  )
  (func $__bp_reserve
    global.get $__heap_ptr
    i32.const 11720
    i32.lt_u
    (if
      (then
      i32.const 11720
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
