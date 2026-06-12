----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
    loop (messages, 0..) { msg, i ->
        @print(msg);
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\08\00\00\00Erro 404")
  (data (i32.const 268) "\0b\00\00\00Sucesso 200")
  (data (i32.const 284) "\09\00\00\00Aviso 500")
  (global $__heap_ptr (mut i32) (i32.const 300))
  (func $main
    (local $__mem0 i32)
    (local $messages i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 16
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 3
    i32.store
    local.get $__mem0
    i32.const 256
    i32.store offset=4
    local.get $__mem0
    i32.const 268
    i32.store offset=8
    local.get $__mem0
    i32.const 284
    i32.store offset=12
    local.get $__mem0
    local.set $messages
    i32.const 0 ;; loop over non-range
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
)
```

----- RUN LOG -----
```logs
```
