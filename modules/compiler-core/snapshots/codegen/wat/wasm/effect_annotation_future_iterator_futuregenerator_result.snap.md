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
#[@futureGenerator]
fn stream() -> @FutureGenerator<i32, string> {
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
  ;; #[@future] / #[@futureGenerator] — eager lowering
  (func $fetch (param $x i32) (result i32)
    local.get $x
    return
  )
  ;; #[@future] / #[@futureGenerator] — eager lowering
  (func $counter (result i32)
    (local $__yield_fn i32)
    i32.const 0
    call $__arr_new
    local.set $__yield_fn
    local.get $__yield_fn
    i32.const 1
    call $__arr_push
    local.set $__yield_fn
    local.get $__yield_fn
    i32.const 2
    call $__arr_push
    local.set $__yield_fn
    local.get $__yield_fn ;; everything the body yielded
  )
  ;; #[@future] / #[@futureGenerator] — eager lowering
  (func $stream (result i32)
    (local $__yield_fn i32)
    i32.const 0
    call $__arr_new
    local.set $__yield_fn
    local.get $__yield_fn
    i32.const 1
    call $__arr_push
    local.set $__yield_fn
    local.get $__yield_fn ;; everything the body yielded
  )
  (func $parse (param $n i32) (result i32)
    (local $_res0 i32)
    (local $_res1 i32)
    local.get $n
    i32.const 0
    i32.lt_s
    (if (result i32)
      (then
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
  (func $__alloc (param $n i32) (result i32)
    (local $p i32)
    global.get $__heap_ptr
    local.set $p
    global.get $__heap_ptr
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    global.set $__heap_ptr
    local.get $p
  )
  (func $__arr_new (param $n i32) (result i32)
    (local $p i32)
    local.get $n
    i32.const 1
    i32.add
    i32.const 4
    i32.mul
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
    local.get $p
  )
  (func $__arr_push (param $xs i32) (param $x i32) (result i32)
    (local $n i32) (local $p i32)
    local.get $xs
    i32.load
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $xs
    i32.const 4
    i32.add
    local.get $n
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
    i32.const 4
    i32.add
    local.get $n
    i32.const 4
    i32.mul
    i32.add
    local.get $x
    i32.store
    local.get $p
  )
)
```

----- RUN LOG -----
```logs
```
