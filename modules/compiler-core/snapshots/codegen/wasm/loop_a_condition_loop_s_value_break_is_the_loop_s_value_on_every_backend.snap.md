----- SOURCE CODE -- main.bp
```botopink
fn main() {
    var i = 0;
    val found = while (i < 10) { if (i == 4) { break i * 2; }; i = i + 1; };
    @print(found);
    @print(i);
    var k = 0;
    val r = loop { k = k + 1; if (k > 2) { break k; }; };
    @print(r);
    var n = 0;
    val never = while (n < 3) { if (n == 99) { break n; }; n = n + 1; };
    @print(never);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $main
    (local $i i32)
    (local $found i32)
    (local $k i32)
    (local $r i32)
    (local $n i32)
    (local $never i32)
    (local $__found0 i32)
    (local $__got0 i32)
    i32.const 0
    local.set $i
    i32.const 0 ;; §10: a search that never breaks has no value
    local.set $__found0
    i32.const 0 ;; decision 52: it has not broken yet
    local.set $__got0
    (block $__break
      (loop $__continue
    local.get $i
    i32.const 10
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $i
    i32.const 4
    i32.eq
    (if (result i32)
      (then
    local.get $i
    i32.const 2
    i32.mul
    local.set $__found0
    i32.const 1 ;; decision 52: it broke, so it has a value
    local.set $__got0
    br $__break
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $i
    i32.const 1
    i32.add
    local.set $i
        br $__continue
      )
    )
    local.get $__found0
    local.set $found
    local.get $found
    local.get $__got0
    call $__print_loop_i32
    local.get $i
    call $__print_i32
    i32.const 0
    local.set $k
    i32.const 0 ;; §10: a search that never breaks has no value
    local.set $__found0
    i32.const 0 ;; decision 52: it has not broken yet
    local.set $__got0
    (block $__break
      (loop $__continue
    i32.const 1
        i32.eqz
        br_if $__break
    local.get $k
    i32.const 1
    i32.add
    local.set $k
    local.get $k
    i32.const 2
    i32.gt_s
    (if (result i32)
      (then
    local.get $k
    local.set $__found0
    i32.const 1 ;; decision 52: it broke, so it has a value
    local.set $__got0
    br $__break
      )
      (else
        i32.const 0
      )
    )
    drop
        br $__continue
      )
    )
    local.get $__found0
    local.set $r
    local.get $r
    local.get $__got0
    call $__print_loop_i32
    i32.const 0
    local.set $n
    i32.const 0 ;; §10: a search that never breaks has no value
    local.set $__found0
    i32.const 0 ;; decision 52: it has not broken yet
    local.set $__got0
    (block $__break
      (loop $__continue
    local.get $n
    i32.const 3
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $n
    i32.const 99
    i32.eq
    (if (result i32)
      (then
    local.get $n
    local.set $__found0
    i32.const 1 ;; decision 52: it broke, so it has a value
    local.set $__got0
    br $__break
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $n
    i32.const 1
    i32.add
    local.set $n
        br $__continue
      )
    )
    local.get $__found0
    local.set $never
    local.get $never
    local.get $__got0
    call $__print_loop_i32
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   32..64 float fraction   64..128 i32 digits
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
  (func $__print_null
    i32.const 176
    i32.const 1819047278
    i32.store
    i32.const 176
    i32.const 4
    call $__write_bytes
  )
  (func $__print_loop_i32_raw (param $v i32) (param $got i32)
    local.get $got
    (if
      (then
        local.get $v
        call $__print_i32_raw
      )
      (else
        call $__print_null
      )
    )
  )
  (func $__print_loop_i32 (param $v i32) (param $got i32)
    local.get $v
    local.get $got
    call $__print_loop_i32_raw
    call $__print_nl
  )
)
```

----- RUN LOG -----
```logs
8
4
3
null
```
