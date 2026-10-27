----- SOURCE CODE -- main.bp
```botopink
fn allThree(a: bool, b: bool, c: bool) -> bool {
    return a && b && c;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $allThree (param $a i32) (param $b i32) (param $c i32) (result i32)
    local.get $a
    (if (result i32)
      (then
    local.get $b
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    local.get $c
      )
      (else
    i32.const 0
      )
    )
    return
  )
)
```

----- RUN LOG -----
```logs
```
