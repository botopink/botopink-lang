----- SOURCE CODE -- main.bp
```botopink
val HttpMethod = type {
    Get,
    Post,
    Put,
    Delete,
    fn name(m: Self) -> string {
        val label = case m {
            Get -> "GET";
            Post -> "POST";
            Put -> "PUT";
            _ -> "DELETE";
        };
        return label;
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\03\00\00\00GET")
  (data (i32.const 264) "\04\00\00\00POST")
  (data (i32.const 272) "\03\00\00\00PUT")
  (data (i32.const 280) "\06\00\00\00DELETE")
  (global $__heap_ptr (mut i32) (i32.const 292))
  (func $HttpMethod_name (param $m i32) (result i32)
    (local $label i32)
    (local $__case_0 i32)
    local.get $m
    local.set $__case_0
    local.get $__case_0
    i32.const 0 ;; Get
    i32.eq
    (if (result i32)
      (then
    i32.const 256
      )
      (else
    local.get $__case_0
    i32.const 1 ;; Post
    i32.eq
    (if (result i32)
      (then
    i32.const 264
      )
      (else
    local.get $__case_0
    i32.const 2 ;; Put
    i32.eq
    (if (result i32)
      (then
    i32.const 272
      )
      (else
    i32.const 280
      )
    )
      )
    )
      )
    )
    local.set $label
    local.get $label
    return
  )
)
```

----- RUN LOG -----
```logs
```
