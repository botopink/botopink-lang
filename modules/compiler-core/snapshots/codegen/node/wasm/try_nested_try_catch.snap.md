----- SOURCE CODE -- main.bp
```botopink
record DbError { msg: string }
fn inner() -> @Result(i32, DbError) {
    throw DbError(msg: "conn refused");
}
fn outer() -> @Result(i32, DbError) {
    throw DbError(msg: "timeout");
}
fn process() -> i32 {
    val a = try inner() catch 0;
    val b = try outer() catch a;
    return a + b;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "conn refused")
  (data (i32.const 268) "timeout")
  (global $__heap_ptr (mut i32) (i32.const 276))
  (func $inner (result i32)
    i32.const 256
    call $DbError
    unreachable
  )
  (func $outer (result i32)
    i32.const 268
    call $DbError
    unreachable
  )
  (func $process (result i32)
    (local $a i32)
    (local $b i32)
    call $inner
    local.set $a
    call $outer
    local.set $b
    local.get $a
    local.get $b
    i32.add
    return
  )
)
```

----- RUN LOG -----
```logs
```
