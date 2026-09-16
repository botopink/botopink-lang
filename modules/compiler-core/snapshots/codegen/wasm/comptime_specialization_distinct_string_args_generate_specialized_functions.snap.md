----- SOURCE CODE -- main.bp
```botopink
fn build(prefix comptime: string, name: string) -> string {
    return prefix + ": " + name;
}

fn main() {
    val r1 = build("INFO", "Sistema iniciado");
    val r2 = build("WARN", "Memória alta");
    val r3 = build("INFO", "Log replicado");
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\10\00\00\00Sistema iniciado")
  (data (i32.const 276) "\0d\00\00\00Memória alta")
  (data (i32.const 296) "\0d\00\00\00Log replicado")
  (data (i32.const 316) "\04\00\00\00INFO")
  (data (i32.const 324) "\02\00\00\00: ")
  (data (i32.const 332) "\04\00\00\00WARN")
  (global $__heap_ptr (mut i32) (i32.const 340))
  (func $main
    (local $r1 i32)
    (local $r2 i32)
    (local $r3 i32)
    i32.const 256
    call $build_$0
    local.set $r1
    i32.const 276
    call $build_$1
    local.set $r2
    i32.const 296
    call $build_$0
    local.set $r3
  )
  (func $build_$0 (param $name i32) (result i32)
    (local $prefix i32)
    i32.const 316
    local.set $prefix
    local.get $prefix
    i32.const 324
    call $__str_concat
    local.get $name
    call $__str_concat
    return
  )
  (func $build_$1 (param $name i32) (result i32)
    (local $prefix i32)
    i32.const 332
    local.set $prefix
    local.get $prefix
    i32.const 324
    call $__str_concat
    local.get $name
    call $__str_concat
    return
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__str_concat (param $a i32) (param $b i32) (result i32)
    (local $base i32) (local $alen i32) (local $blen i32)
    local.get $a
    i32.load
    local.set $alen
    local.get $b
    i32.load
    local.set $blen
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
