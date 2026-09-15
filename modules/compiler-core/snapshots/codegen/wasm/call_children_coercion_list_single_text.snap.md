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
  (data (i32.const 256) "\01\00\00\00n")
  (data (i32.const 264) "\01\00\00\00x")
  (global $__heap_ptr (mut i32) (i32.const 272))
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
)
```

----- RUN LOG -----
```logs
```
