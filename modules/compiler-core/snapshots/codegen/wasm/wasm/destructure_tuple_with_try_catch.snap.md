----- SOURCE CODE -- main.bp
```botopink
record Error { msg: string }
fn fetch() -> #(i32, i32) {
    return #(1, 2);
}
fn f() {
    val #(a, b) = try fetch() catch throw Error(msg: "failed");
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $fetch (result i32)
    i32.const 0 ;; tuple
    return
  )
  (func $f
    (local $a i32)
    (local $b i32)
    call $fetch
    local.set $b
    local.set $a
  )
)
```

----- RUN LOG -----
```logs
```
