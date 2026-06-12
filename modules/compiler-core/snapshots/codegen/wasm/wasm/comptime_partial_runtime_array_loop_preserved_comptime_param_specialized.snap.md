----- SOURCE CODE -- main.bp
```botopink
val COMMANDS = ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    loop (COMMANDS) { cmd ->
        if (cmd == slug) {
            output = input * 2;
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\04\00\00\00calc")
  (data (i32.const 264) "\04\00\00\00noop")
  (global $__heap_ptr (mut i32) (i32.const 272))
  (func $main
    (local $r1 i32)
    (local $r2 i32)
    i32.const 10
    call $execute_$0
    local.set $r1
    i32.const 42
    call $execute_$1
    local.set $r2
  )
  (func $execute_$0 (param $input i32)
    (local $slug i32)
    (local $output i32)
    i32.const 256
    local.set $slug
    i32.const 0
    local.set $output
    i32.const 0 ;; loop over non-range
    drop
    local.get $output
    return
  )
  (func $execute_$1 (param $input i32)
    (local $slug i32)
    (local $output i32)
    i32.const 264
    local.set $slug
    i32.const 0
    local.set $output
    i32.const 0 ;; loop over non-range
    drop
    local.get $output
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
