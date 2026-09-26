----- SOURCE CODE -- main.bp
```botopink
val Maybe = type {
    Nothing,
    Just(value: string),
    fn check(m: Self) -> string {
        return case m {
            Nothing -> "nothing";
            Just(value) -> "just";
        };
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\07\00\00\00nothing")
  (data (i32.const 268) "\04\00\00\00just")
  (global $__heap_ptr (mut i32) (i32.const 276))
  (func $Maybe_check (param $m i32) (result i32)
    (local $value i32)
    (local $__case_0 i32)
    local.get $m
    local.set $__case_0
    local.get $__case_0
    i32.load ;; variant tag
    i32.const 0 ;; Nothing
    i32.eq
    (if (result i32)
      (then
    i32.const 256
      )
      (else
    local.get $__case_0
    i32.load ;; variant tag
    i32.const 1 ;; Just
    i32.eq
    (if (result i32)
      (then
    local.get $__case_0
    i32.load offset=4
    local.set $value
    i32.const 268
      )
      (else
    i32.const 0
      )
    )
      )
    )
    return
  )
)
```

----- RUN LOG -----
```logs
```
