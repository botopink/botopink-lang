----- SOURCE CODE -- main.bp
```botopink
type Maybe<T> {
    Some(value: T),
    None,
}
fn innerLength(b: unknown) -> i32 {
    return case b {
        Maybe.Some(value: v) when (v is string) { v.length }
        Maybe.Some(value: v) { -1 }
        _ { -2 }
    };
}
fn main() {
    val s: unknown = Maybe.Some(value: "abc");
    @print(innerLength(s));
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\14\00\00\00V\nMaybe.Some\01\05valueG")
  (data (i32.const 280) "\01\00\00\00s")
  (data (i32.const 288) "\08\00\00\00P\06string")
  (data (i32.const 300) "\03\00\00\00abc")
  (global $__heap_ptr (mut i32) (i32.const 320))
  (func $innerLength (param $b i32) (result i32)
    (local $v i32)
    (local $__case_0 i32)
    (local $v__is0 i32)
    local.get $b
    local.set $__case_0
    local.get $__case_0
    i32.load ;; variant tag
    i32.const 0 ;; Some
    i32.eq
    (if (result i32)
      (then
    local.get $__case_0
    i32.load offset=4
    local.set $v
    local.get $v
    call $__unknown_kind
    i32.const 115
    i32.eq
    (if (result i32)
      (then
    local.get $v
    i32.load ;; unknown: the proven payload
    local.set $v__is0
    local.get $v__is0
    call $__std_text_length
      )
      (else
    local.get $__case_0
    i32.load ;; variant tag
    i32.const 0 ;; Some
    i32.eq
    (if (result i32)
      (then
    local.get $__case_0
    i32.load offset=4
    local.set $v
    i32.const 0
    i32.const 1
    call $__i32_sub_chk
      )
      (else
    i32.const 0
    i32.const 2
    call $__i32_sub_chk
      )
    )
      )
    )
      )
      (else
    local.get $__case_0
    i32.load ;; variant tag
    i32.const 0 ;; Some
    i32.eq
    (if (result i32)
      (then
    local.get $__case_0
    i32.load offset=4
    local.set $v
    i32.const 0
    i32.const 1
    call $__i32_sub_chk
      )
      (else
    i32.const 0
    i32.const 2
    call $__i32_sub_chk
      )
    )
      )
    )
    return
  )
  (func $main
    (local $__mem0 i32)
    (local $s i32)
    (local $__mem1 i32)
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 284
    i32.store offset=12
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    i32.const 8
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 292
    i32.store
    local.get $__mem1
    i32.const 300
    i32.store offset=4 ;; unknown: box a string
    local.get $__mem1
    i32.const 4
    i32.add
    i32.store offset=8
    local.get $__mem0
    i32.const 4
    i32.add
    local.set $s
    local.get $s
    call $innerLength
    call $__print_i32
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
  (func $__write_bytes (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__print_nl
    i32.const 8
    i32.const 10
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  ;; separator between the arguments of a multi-argument `@print`
  (func $__print_sp
    i32.const 8
    i32.const 32
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i32 (param $n i32)
    local.get $n
    call $__print_i32_raw
    call $__print_nl
  )
  (func $__print_i32_raw (param $n i32)
    (local $buf i32) (local $len i32) (local $neg i32) (local $d i32)
    (local $i i32) (local $j i32) (local $tmp i32)
    i32.const 64
    local.set $buf
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 1
        local.set $neg
        i32.const 0
        local.get $n
        i32.sub
        local.set $n
      )
    )
    (block $done
      (loop $digits
        local.get $n
        i32.const 10
        i32.rem_u
        i32.const 48
        i32.add
        local.set $d
        local.get $buf
        local.get $len
        i32.add
        local.get $d
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
        local.get $n
        i32.const 10
        i32.div_u
        local.set $n
        local.get $n
        i32.const 0
        i32.gt_u
        br_if $digits
      )
    )
    ;; reverse
    i32.const 0
    local.set $i
    local.get $len
    i32.const 1
    i32.sub
    local.set $j
    (block $rdone
      (loop $rev
        local.get $i
        local.get $j
        i32.ge_u
        br_if $rdone
        local.get $buf
        local.get $i
        i32.add
        i32.load8_u
        local.set $tmp
        local.get $buf
        local.get $i
        i32.add
        local.get $buf
        local.get $j
        i32.add
        i32.load8_u
        i32.store8
        local.get $buf
        local.get $j
        i32.add
        local.get $tmp
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        local.get $j
        i32.const 1
        i32.sub
        local.set $j
        br $rev
      )
    )
    ;; add neg sign + newline
    ;; shift the digits one byte right to make room for '-'
    ;; (dst = buf+1, NOT buf+len: the latter moved them `len`
    ;;  bytes and printed -12 as -21)
    local.get $neg
    (if
      (then
        local.get $buf
        i32.const 1
        i32.add
        local.get $buf
        local.get $len
        call $__memmove
        local.get $buf
        i32.const 45
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
      )
    )
    local.get $buf
    local.get $len
    call $__write_bytes
  )
  (func $__memmove (param $dst i32) (param $src i32) (param $len i32)
    (local $i i32)
    local.get $len
    i32.const 1
    i32.sub
    local.set $i
    (block $done
      (loop $loop
        local.get $i
        i32.const 0
        i32.lt_s
        br_if $done
        local.get $dst
        local.get $i
        i32.add
        local.get $src
        local.get $i
        i32.add
        i32.load8_u
        i32.store8
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        br $loop
      )
    )
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
  (func $__unknown_kind (param $v i32) (result i32)
    (local $d i32)
    local.get $v
    i32.const 256
    i32.lt_u
    (if
      (then
        i32.const 0
        return
      )
    )
    local.get $v
    i32.const 4
    i32.sub
    i32.load
    local.set $d
    local.get $d
    i32.load8_u
    i32.const 80
    i32.ne
    (if
      (then
        local.get $d
        i32.load8_u
        return
      )
    )
    local.get $d
    i32.load8_u offset=2
  )
  (func $__unknown_int_in (param $v i32) (param $lo i32) (param $hi i32) (result i32)
    (local $k i32) (local $x f64)
    local.get $v
    call $__unknown_kind
    local.set $k
    local.get $k
    i32.const 105
    i32.eq
    (if
      (then
        local.get $v
        i32.load
        local.get $lo
        i32.ge_s
        local.get $v
        i32.load
        local.get $hi
        i32.le_s
        i32.and
        return
      )
    )
    local.get $k
    i32.const 102
    i32.ne
    (if
      (then
        i32.const 0
        return
      )
    )
    local.get $v
    f64.load
    local.set $x
    local.get $x
    f64.floor
    local.get $x
    f64.ne
    (if
      (then
        i32.const 0
        return
      )
    )
    local.get $x
    local.get $lo
    f64.convert_i32_s
    f64.ge
    local.get $x
    local.get $hi
    f64.convert_i32_s
    f64.le
    i32.and
  )
  (func $__unknown_as_i32 (param $v i32) (result i32)
    local.get $v
    call $__unknown_kind
    i32.const 102
    i32.eq
    (if
      (then
        local.get $v
        f64.load
        i32.trunc_f64_s
        return
      )
    )
    local.get $v
    i32.load
  )
  (func $__unknown_as_f64 (param $v i32) (result f64)
    local.get $v
    call $__unknown_kind
    i32.const 105
    i32.eq
    (if
      (then
        local.get $v
        i32.load
        f64.convert_i32_s
        return
      )
    )
    local.get $v
    f64.load
  )
  (func $__unknown_eq (param $a i32) (param $b i32) (result i32)
    (local $ka i32) (local $kb i32)
    local.get $a
    call $__unknown_kind
    local.set $ka
    local.get $b
    call $__unknown_kind
    local.set $kb
    local.get $ka
    i32.const 105
    i32.eq
    local.get $ka
    i32.const 102
    i32.eq
    i32.or
    local.get $kb
    i32.const 105
    i32.eq
    local.get $kb
    i32.const 102
    i32.eq
    i32.or
    i32.and
    (if
      (then
        local.get $a
        call $__unknown_as_f64
        local.get $b
        call $__unknown_as_f64
        f64.eq
        return
      )
    )
    local.get $ka
    i32.const 115
    i32.eq
    local.get $kb
    i32.const 115
    i32.eq
    i32.and
    (if
      (then
        local.get $a
        i32.load
        local.get $b
        i32.load
        call $__str_eq
        return
      )
    )
    local.get $ka
    i32.const 98
    i32.eq
    local.get $kb
    i32.const 98
    i32.eq
    i32.and
    (if
      (then
        local.get $a
        i32.load
        local.get $b
        i32.load
        i32.eq
        return
      )
    )
    local.get $a
    local.get $b
    i32.eq
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
  ;; std-wasm (decision 440): its functions, transpiled from std_wasm.wasm
  ;; __std_f265 — from std_wasm.wasm (sha256 5ac39cdc3016)
  ;; std:text.length — from std_wasm.wasm (sha256 5a17b89b2a1a)
)
```

----- RUN LOG -----
```logs
3
```
