----- SOURCE CODE -- main.bp
```botopink
val COMMANDS = ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    for (COMMANDS) { cmd ->
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
  (start $__init_globals)
  (data (i32.const 256) "\04\00\00\00calc")
  (data (i32.const 264) "\04\00\00\00noop")
  (data (i32.const 272) "\04\00\00\00help")
  (global $__heap_ptr (mut i32) (i32.const 280))
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
    (local $slug i32)
    (local $output i32)
    (local $cmd i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    i32.const 256
    local.set $slug
    i32.const 0
    local.set $output
    global.get $COMMANDS
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $cmd
    local.get $cmd
    local.get $slug
    call $__str_eq
    (if (result i32)
      (then
    local.get $input
    i32.const 2
    i32.mul
    local.set $output
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $output
    return
  )
  (func $execute_$1 (param $input i32) (result i32)
    (local $slug i32)
    (local $output i32)
    (local $cmd i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    i32.const 264
    local.set $slug
    i32.const 0
    local.set $output
    global.get $COMMANDS
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $cmd
    local.get $cmd
    local.get $slug
    call $__str_eq
    (if (result i32)
      (then
    local.get $input
    i32.const 2
    i32.mul
    local.set $output
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $output
    return
  )
  (func $__init_globals
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 16
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 3
    i32.store
    local.get $__mem0
    i32.const 256
    i32.store offset=4
    local.get $__mem0
    i32.const 264
    i32.store offset=8
    local.get $__mem0
    i32.const 272
    i32.store offset=12
    local.get $__mem0
    global.set $COMMANDS
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__str_eq (param $a i32) (param $b i32) (result i32)
    (local $i i32) (local $alen i32)
    local.get $a
    i32.load
    local.set $alen
    local.get $alen
    local.get $b
    i32.load
    i32.ne
    (if
      (then i32.const 0 return)
    )
    (block $done
      (loop $cmp
        local.get $i
        local.get $alen
        i32.ge_u
        br_if $done
        local.get $a
        local.get $i
        i32.add
        i32.load8_u offset=4
        local.get $b
        local.get $i
        i32.add
        i32.load8_u offset=4
        i32.ne
        (if
          (then i32.const 0 return)
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cmp
      )
    )
    i32.const 1
  )
)
```

----- RUN LOG -----
```logs
```
