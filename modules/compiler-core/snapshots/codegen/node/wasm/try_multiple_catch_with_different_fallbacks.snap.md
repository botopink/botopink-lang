----- SOURCE CODE -- main.bp
```botopink
record UserError { msg: string }
fn fetchName() -> @Result(string, UserError) {
    throw UserError(msg: "name missing");
}
fn fetchAge() -> @Result(i32, UserError) {
    throw UserError(msg: "age missing");
}
fn loadUser() {
    val name = try fetchName() catch "anonymous";
    val age = try fetchAge() catch 0;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "name missing")
  (data (i32.const 268) "age missing")
  (global $__heap_ptr (mut i32) (i32.const 280))
  (func $fetchName (result i32)
    i32.const 256
    call $UserError
    unreachable
  )
  (func $fetchAge (result i32)
    i32.const 268
    call $UserError
    unreachable
  )
  (func $loadUser
    (local $name i32)
    (local $age i32)
    call $fetchName
    local.set $name
    call $fetchAge
    local.set $age
  )
)
```

----- RUN LOG -----
```logs
```
