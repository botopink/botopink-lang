----- SOURCE CODE -- main.bp
```botopink
fn multiply(comptime factor: i32, x: i32) -> i32 {
    return x * factor;
}

fn calculate() {
    val double = multiply(2, 21);
    val triple = multiply(3, 21);
    val doubleAgain = multiply(2, 10);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $calculate
    (local $double i32)
    (local $triple i32)
    (local $doubleAgain i32)
    i32.const 21
    call $multiply_$0
    local.set $double
    i32.const 21
    call $multiply_$1
    local.set $triple
    i32.const 10
    call $multiply_$0
    local.set $doubleAgain
  )
  (func $multiply_$0 (param $x i32)
    (local $factor i32)
    i32.const 2
    local.set $factor
    local.get $x
    local.get $factor
    i32.mul
    return
  )
  (func $multiply_$1 (param $x i32)
    (local $factor i32)
    i32.const 3
    local.set $factor
    local.get $x
    local.get $factor
    i32.mul
    return
  )
)
```

----- RUN LOG -----
```logs
```
