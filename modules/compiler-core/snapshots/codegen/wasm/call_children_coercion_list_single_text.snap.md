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
  (memory (export "memory") 1)
  (start $__init_globals)
  (data (i32.const 256) "\01\00\00\00n")
  (data (i32.const 264) "\01\00\00\00x")
  (data (i32.const 272) "\02\00\00\00hi")
  (global $__heap_ptr (mut i32) (i32.const 280))
  (func $node (result i32)
    i32.const 256
    return
  )
  (func $box (param $children i32) (result i32)
    i32.const 264
    return
  )
  (global $many (mut i32) (i32.const 0))
  (global $one (mut i32) (i32.const 0))
  (global $txt (mut i32) (i32.const 0))
  (func $__init_globals
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
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
    i32.const 272
    call $box
    global.set $txt
  )
)
```

----- RUN LOG -----
```logs
```
