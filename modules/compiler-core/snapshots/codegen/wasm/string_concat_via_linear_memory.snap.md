----- SOURCE CODE -- main.bp
```botopink
fn greeting() -> string {
    return "Hello, " + "World";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\07\00\00\00Hello, ")
  (data (i32.const 268) "\05\00\00\00World")
  (global $__heap_ptr (mut i32) (i32.const 280))
  (func $greeting (result i32)
    i32.const 256 ;; "Hello, " ptr
    i32.const 7 ;; "Hello, " len
    i32.const 268 ;; "World" ptr
    i32.const 5 ;; "World" len
    call $__str_concat
    return
  )
  (func $__str_concat (param $a i32) (param $alen i32) (param $b i32) (param $blen i32) (result i32)
    (local $base i32)
    global.get $__heap_ptr
    local.set $base
    ;; bump heap by 4 (length prefix) + alen + blen
    global.get $__heap_ptr
    i32.const 4
    local.get $alen
    i32.add
    local.get $blen
    i32.add
    i32.add
    global.set $__heap_ptr
    ;; store combined length prefix
    local.get $base
    local.get $alen
    local.get $blen
    i32.add
    i32.store
    ;; copy a's bytes: base+4 <- a+4
    local.get $base
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.add
    local.get $alen
    memory.copy
    ;; copy b's bytes: base+4+alen <- b+4
    local.get $base
    i32.const 4
    i32.add
    local.get $alen
    i32.add
    local.get $b
    i32.const 4
    i32.add
    local.get $blen
    memory.copy
    local.get $base
  )
)
```

----- RUN LOG -----
```logs
```
