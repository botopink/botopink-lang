----- SOURCE CODE -- main.bp
```botopink
record ApiError { msg: string }
fn fetch() -> @Result(i32, ApiError) {
    throw ApiError(msg: "not found");
}
fn strict() -> @Result(i32, string) {
    val r = try fetch() catch throw "fetch failed";
    return r;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "not found")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $fetch (result i32)
    i32.const 256
    call $ApiError
    unreachable
  )
  (func $strict (result i32)
    (local $r i32)
    call $fetch
    local.set $r
    local.get $r
    return
  )
)
```

----- RUN LOG -----
```logs
```
