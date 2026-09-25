----- SOURCE CODE -- main.bp
```botopink
fn main() -> bool {
    return isEven(10);
}

fn isEven(n: i32) -> bool {
    if (n == 0) { return true; };
    return isOdd(n - 1);
}

fn isOdd(n: i32) -> bool {
    if (n == 0) { return false; };
    return isEven(n - 1);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $main (result i32)
    i32.const 10
    call $isEven
    return
  )
  (func $isEven (param $n i32) (result i32)
    local.get $n
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    i32.const 1
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $n
    i32.const 1
    i32.sub
    call $isOdd
    return
  )
  (func $isOdd (param $n i32) (result i32)
    local.get $n
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    i32.const 0
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $n
    i32.const 1
    i32.sub
    call $isEven
    return
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
    drop
  )
)
```

----- RUN LOG -----
```logs
```
