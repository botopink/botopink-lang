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
  (func $build_$0 (param $name i32)
    (local $prefix i32)
    i32.const 316
    local.set $prefix
    local.get $prefix
    i32.const 324
    i32.add
    local.get $name
    i32.add
    return
  )
  (func $build_$1 (param $name i32)
    (local $prefix i32)
    i32.const 332
    local.set $prefix
    local.get $prefix
    i32.const 324
    i32.add
    local.get $name
    i32.add
    return
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
)
```

----- RUN LOG -----
```logs
```
