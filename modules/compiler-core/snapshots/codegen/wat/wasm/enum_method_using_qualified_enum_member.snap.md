----- SOURCE CODE -- main.bp
```botopink
val Status = type {
    Active,
    Inactive,
    fn isDefault(s: Self) -> string {
        val current = Status.Active;
        return current;
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $Status_isDefault (param $s i32) (result i32)
    (local $current i32)
    i32.const 0 ;; Status.Active
    local.set $current
    local.get $current
    return
  )
)
```

----- RUN LOG -----
```logs
```
