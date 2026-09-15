----- SOURCE CODE -- main.bp
```botopink
fn getName(name: ?string) -> string {
    if (name) { n ->
        return n;
    };
    return "unknown";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\07\00\00\00unknown")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $getName (param $name i32) (result i32)
    local.get $name
    (if (result i32)
      (then
    global.get $n
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    i32.const 256
    return
  )
)
```

----- RUN LOG -----
```logs
```
