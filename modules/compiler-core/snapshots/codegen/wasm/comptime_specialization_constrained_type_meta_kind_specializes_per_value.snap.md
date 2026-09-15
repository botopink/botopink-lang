----- SOURCE CODE -- main.bp
```botopink
fn coerce(comptime v: type string | int | bool, x: i32) -> i32 {
    return x;
}

fn main() {
    val a = coerce("s", 1);
    val b = coerce(7, 2);
    val c = coerce("s", 3);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $main
    (local $a i32)
    (local $b i32)
    (local $c i32)
    i32.const 1
    call $coerce_$0
    local.set $a
    i32.const 2
    call $coerce_$1
    local.set $b
    i32.const 3
    call $coerce_$0
    local.set $c
  )
  (func $coerce_$0 (param $x i32)
    local.get $x
    return
  )
  (func $coerce_$1 (param $x i32)
    local.get $x
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
