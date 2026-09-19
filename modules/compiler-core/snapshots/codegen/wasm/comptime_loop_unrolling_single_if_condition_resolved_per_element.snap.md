----- SOURCE CODE -- main.bp
```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

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

----- COMPTIME VALUES -- main
```text
ct_0: val COMMANDS = comptime ["calc", "noop", "help"] → ["calc", "noop", "help"]
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (start $__init_globals)
  (data (i32.const 256) "\18\00\00\00[\"calc\", \"noop\", \"help\"]")
  (global $__heap_ptr (mut i32) (i32.const 284))
  (global $COMMANDS (mut i32) (i32.const 0))
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
  (func $execute_$0 (param $input i32) (result i32)
    (local $output i32)
    i32.const 0
    local.set $output
    local.get $input
    i32.const 2
    i32.mul
    local.set $output
    local.get $output
    return
  )
  (func $execute_$1 (param $input i32) (result i32)
    (local $output i32)
    i32.const 0
    local.set $output
    local.get $input
    i32.const 2
    i32.mul
    local.set $output
    local.get $output
    return
  )
  (func $__init_globals
    i32.const 256 ;; folded non-numeric literal
    global.set $COMMANDS
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
)
```

----- RUN LOG -----
```logs
```
