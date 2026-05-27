----- SOURCE CODE -- main.bp
```botopink
record IoError { path: string }
fn step1() -> @Result(i32, IoError) {
    throw IoError(path: "/data");
}
fn step2(x: i32) -> @Result(i32, IoError) {
    throw IoError(path: "/out");
}
fn pipeline() -> @Result(i32, IoError) {
    val a = try step1();
    val b = try step2(a);
    return b;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "/data")
  (data (i32.const 264) "/out")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $step1 (result i32)
    i32.const 256
    call $IoError
    unreachable
  )
  (func $step2 (param $x i32) (result i32)
    i32.const 264
    call $IoError
    unreachable
  )
  (func $pipeline (result i32)
    (local $a i32)
    (local $b i32)
    call $step1
    local.set $a
    local.get $a
    call $step2
    local.set $b
    local.get $b
    return
  )
)
```

----- RUN LOG -----
```logs
```
