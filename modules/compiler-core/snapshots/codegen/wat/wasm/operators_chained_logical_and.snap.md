----- SOURCE CODE -- main.bp
```botopink
fn allThree(a: bool, b: bool, c: bool) -> bool {
    return a && b && c;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $allThree (param $a i32) (param $b i32) (param $c i32) (result i32)
    local.get $a
    local.get $b
    i32.and
    local.get $c
    i32.and
    return
  )
)
```

----- RUN LOG -----
```logs
```
