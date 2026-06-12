----- SOURCE CODE -- main.bp
```botopink
*fn fetch(x: i32) -> @Future<i32> {
    return x;
}
*fn loadTwice(x: i32) -> @Future<i32> {
    val a = await fetch(x);
    return a + a;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; *fn (async/generator) — eager lowering
  (func $fetch (param $x i32) (result i32)
    local.get $x
    return
  )
  ;; *fn (async/generator) — eager lowering
  (func $loadTwice (param $x i32) (result i32)
    (local $a i32)
    local.get $x
    call $fetch
    local.set $a
    local.get $a
    local.get $a
    i32.add
    return
  )
)
```

----- RUN LOG -----
```logs
```
