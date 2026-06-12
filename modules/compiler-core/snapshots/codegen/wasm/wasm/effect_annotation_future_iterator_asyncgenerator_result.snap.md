----- SOURCE CODE -- main.bp
```botopink
#[@future]
fn fetch(x: i32) -> @Future<i32> {
    return x;
}
#[@iterator]
fn counter() -> @Iterator<i32> {
    yield 1;
    yield 2;
}
#[@asyncGenerator]
fn stream() -> @AsyncIterator<i32, string> {
    yield 1;
}
#[@result]
fn parse(n: i32) -> @Result<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\08\00\00\00negative")
  (global $__heap_ptr (mut i32) (i32.const 268))
  ;; *fn (async/generator) — eager lowering
  (func $fetch (param $x i32) (result i32)
    local.get $x
    return
  )
  ;; *fn (async/generator) — eager lowering
  (func $counter (result i32)
    i32.const 1
    i32.const 2
  )
  ;; *fn (async/generator) — eager lowering
  (func $stream (result i32)
    i32.const 1
  )
  (func $parse (param $n i32) (result i32)
    local.get $n
    i32.const 0
    i32.lt_s
    (if (result i32)
      (then
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
    i32.const 256
    i32.store offset=4 ;; payload
    local.get $_res0
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    (local $_res1 i32)
    global.get $__heap_ptr
    local.set $_res1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $_res1
    i32.const 0
    i32.store ;; Result tag (Ok)
    local.get $_res1
    local.get $n
    i32.store offset=4 ;; payload
    local.get $_res1
    return
  )
)
```

----- RUN LOG -----
```logs
```
