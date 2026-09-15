----- SOURCE CODE -- main.bp
```botopink
fn label(a: string, b: string) -> string {
    return "${a}-${b}";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\00\00\00\00")
  (data (i32.const 260) "\01\00\00\00-")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $label (param $a i32) (param $b i32) (result i32)
    i32.const 256
    local.get $a
    i32.add
    i32.const 260
    i32.add
    local.get $b
    i32.add
    return
  )
)
```

----- RUN LOG -----
```logs
```
