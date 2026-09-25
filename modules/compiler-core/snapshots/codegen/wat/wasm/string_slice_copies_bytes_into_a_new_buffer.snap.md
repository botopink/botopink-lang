----- SOURCE CODE -- main.bp
```botopink
fn first3() -> string {
    val s = "hello";
    return s.slice(0, 3);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\05\00\00\00hello")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $first3 (result i32)
    (local $s i32)
    i32.const 256
    local.set $s
    local.get $s
    i32.const 0
    i32.const 3
    call $__str_slice
    return
  )
  (func $__str_slice (param $src i32) (param $start i32) (param $end i32) (result i32)
    (local $newlen i32) (local $dst i32)
    local.get $end
    local.get $start
    i32.sub
    local.set $newlen
    global.get $__heap_ptr
    local.set $dst
    ;; bump heap by 4 (length prefix) + newlen
    global.get $__heap_ptr
    i32.const 4
    local.get $newlen
    i32.add
    i32.add
    global.set $__heap_ptr
    ;; store length prefix
    local.get $dst
    local.get $newlen
    i32.store
    ;; copy bytes: dst+4 <- src+4+start
    local.get $dst
    i32.const 4
    i32.add
    local.get $src
    i32.const 4
    i32.add
    local.get $start
    i32.add
    local.get $newlen
    memory.copy
    local.get $dst
  )
)
```

----- RUN LOG -----
```logs
```
