----- SOURCE CODE -- main.bp
```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

fn execute(comptime slug: @Expr<string>, input: i32) -> i32 {
    var output = 0;
    for (COMMANDS) { cmd ->
        if (cmd == slug.value) {
            if (cmd == "calc") {
                output = input * 2;
            } else if (cmd == "noop") {
                output = input;
            };
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
    (local $output i32)
    i32.const 0
    local.set $output
    local.get $input
    i32.const 2
    call $__i32_mul_chk
    local.set $output
    local.get $output
    return
  )
  (func $execute_$1 (param $input i32) (result i32)
    (local $output i32)
    i32.const 0
    local.set $output
    local.get $input
    local.set $output
    local.get $output
    return
  )
  (func $__init_globals
    (local $__mem0 i32)
    i32.const 16
    call $__alloc
    local.set $__mem0
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
  (func $__alloc (param $n i32) (result i32)
    (local $p i32) (local $e i32)
    global.get $__heap_ptr
    local.set $p
    local.get $p
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    local.set $e
    local.get $e
    local.get $p
    i32.lt_u
    (if
      (then
        unreachable
      )
    )
    local.get $e
    memory.size
    i32.const 16
    i32.shl
    i32.gt_u
    (if
      (then
        local.get $e
        i32.const 65535
        i32.add
        i32.const 16
        i32.shr_u
        memory.size
        i32.sub
        memory.grow
        i32.const -1
        i32.eq
        (if
          (then
            unreachable
          )
        )
      )
    )
    local.get $e
    global.set $__heap_ptr
    local.get $p
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.add
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.sub
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.mul
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.add
    local.set $r
    local.get $a
    local.get $r
    i64.xor
    local.get $b
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.sub
    local.set $r
    local.get $a
    local.get $b
    i64.xor
    local.get $a
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (result i64)
    (local $r i64)
    local.get $a
    i64.const -1
    i64.eq
    local.get $b
    i64.const -9223372036854775808
    i64.eq
    i32.and
    (if
      (then
        unreachable
      )
    )
    local.get $a
    local.get $b
    i64.mul
    local.set $r
    local.get $a
    i64.eqz
    i32.eqz
    (if
      (then
        local.get $r
        local.get $a
        i64.div_s
        local.get $b
        i64.ne
        (if
          (then
            unreachable
          )
        )
      )
    )
    local.get $r
  )
)
```

----- RUN LOG -----
```logs
```
