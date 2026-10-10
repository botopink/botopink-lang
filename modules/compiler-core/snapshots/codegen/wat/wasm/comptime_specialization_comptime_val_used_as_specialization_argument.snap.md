----- SOURCE CODE -- main.bp
```botopink
val base = comptime 10 + 5;

fn scale(comptime factor: @Expr<i32>, value: i32) -> i32 {
    return value * factor.value;
}

fn main() {
    val doubled = scale(2, base);
    val tripled = scale(3, base);
    val doubledAgain = scale(2, 100);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val base = comptime 10 + 5 → 15
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $base i32 (i32.const 15))
  (func $main
    (local $doubled i32)
    (local $tripled i32)
    (local $doubledAgain i32)
    global.get $base
    call $scale_$0
    local.set $doubled
    global.get $base
    call $scale_$1
    local.set $tripled
    i32.const 100
    call $scale_$0
    local.set $doubledAgain
  )
  (func $scale_$0 (param $value i32) (result i32)
    (local $factor i32)
    i32.const 2
    local.set $factor
    local.get $value
    local.get $factor
    call $__i32_mul_chk
    return
  )
  (func $scale_$1 (param $value i32) (result i32)
    (local $factor i32)
    i32.const 3
    local.set $factor
    local.get $value
    local.get $factor
    call $__i32_mul_chk
    return
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
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
