----- SOURCE CODE -- main.bp
```botopink
record IoError { path: string }
*fn step1() -> @Result<i32, IoError> {
    throw IoError(path: "/data");
}
*fn step2(x: i32) -> @Result<i32, IoError> {
    throw IoError(path: "/out");
}
*fn pipeline() -> @Result<i32, IoError> {
    val a = try step1();
    val b = try step2(a);
    return b;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\05\00\00\00/data")
  (data (i32.const 268) "\04\00\00\00/out")
  (global $__heap_ptr (mut i32) (i32.const 276))
  (func $step1 (result i32)
    (local $__mem0 i32)
    (local $_res0 i32)
    global.get $__heap_ptr
    local.set $_res0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $_res0
    i32.const 1
    i32.store ;; Result tag (Error)
    local.get $_res0
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 256
    i32.store
    local.get $__mem0
    i32.store offset=4 ;; payload
    local.get $_res0
    return
  )
  (func $step2 (param $x i32) (result i32)
    (local $__mem0 i32)
    (local $_res0 i32)
    global.get $__heap_ptr
    local.set $_res0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $_res0
    i32.const 1
    i32.store ;; Result tag (Error)
    local.get $_res0
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 268
    i32.store
    local.get $__mem0
    i32.store offset=4 ;; payload
    local.get $_res0
    return
  )
  (func $pipeline (result i32)
    (local $_try0 i32)
    (local $_try1 i32)
    (local $a i32)
    (local $b i32)
    call $step1
    local.set $_try0
    local.get $_try0
    i32.load ;; Result tag (0 = Ok, non-zero = Error)
    (if
      (then
    local.get $_try0
    return ;; propagate Error
      )
    )
    local.get $_try0
    i32.load offset=4 ;; Ok payload
    local.set $a
    local.get $a
    call $step2
    local.set $_try1
    local.get $_try1
    i32.load ;; Result tag (0 = Ok, non-zero = Error)
    (if
      (then
    local.get $_try1
    return ;; propagate Error
      )
    )
    local.get $_try1
    i32.load offset=4 ;; Ok payload
    local.set $b
    (local $_res0 i32)
    global.get $__heap_ptr
    local.set $_res0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $_res0
    i32.const 0
    i32.store ;; Result tag (Ok)
    local.get $_res0
    local.get $b
    i32.store offset=4 ;; payload
    local.get $_res0
    return
  )
)
```

----- RUN LOG -----
```logs
```
