----- SOURCE CODE -- main.bp
```botopink
fn execute(comptime slug: string, input: i32) -> i32 {
    return input + 0;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
    val r3 = execute("calc", 5);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $main
    (local $r1 i32)
    (local $r2 i32)
    (local $r3 i32)
    i32.const 10
    call $execute_$0
    local.set $r1
    i32.const 42
    call $execute_$1
    local.set $r2
    i32.const 5
    call $execute_$0
    local.set $r3
  )
  (func $execute_$0 (param $input i32)
    local.get $input
    i32.const 0
    i32.add
    return
  )
  (func $execute_$1 (param $input i32)
    local.get $input
    i32.const 0
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
