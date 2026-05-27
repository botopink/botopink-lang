----- SOURCE CODE -- main.bp
```botopink
record CalcError { msg: string }
fn getA() -> @Result(i32, CalcError) {
    throw CalcError(msg: "overflow");
}
fn compute() -> i32 {
    val r = getA() catch 0;
    return r;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "overflow")
  (global $__heap_ptr (mut i32) (i32.const 264))
  (func $getA (result i32)
    i32.const 256
    call $CalcError
    unreachable
  )
  (func $compute (result i32)
    (local $r i32)
    call $getA
    local.set $r
    local.get $r
    return
  )
)
```

----- RUN LOG -----
```logs
```
