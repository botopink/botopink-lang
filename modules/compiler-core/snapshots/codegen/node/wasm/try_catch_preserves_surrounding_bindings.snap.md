----- SOURCE CODE -- main.bp
```botopink
record LoadError { msg: string }
fn load() -> @Result(i32, LoadError) {
    throw LoadError(msg: "not found");
}
fn process() -> i32 {
    val prefix = 10;
    val data = try load() catch 0;
    val suffix = 20;
    return prefix + data + suffix;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "not found")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $load (result i32)
    i32.const 256
    call $LoadError
    unreachable
  )
  (func $process (result i32)
    (local $prefix i32)
    (local $data i32)
    (local $suffix i32)
    i32.const 10
    local.set $prefix
    call $load
    local.set $data
    i32.const 20
    local.set $suffix
    local.get $prefix
    local.get $data
    i32.add
    local.get $suffix
    i32.add
    return
  )
)
```

----- RUN LOG -----
```logs
```
