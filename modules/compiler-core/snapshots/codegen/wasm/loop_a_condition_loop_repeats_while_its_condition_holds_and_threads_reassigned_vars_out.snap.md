----- SOURCE CODE -- main.bp
```botopink
fn count(limit: i32) -> i32 {
    var i = 0;
    var acc = "";
    loop (i < limit) {
        acc = acc + i.toString();
        i = i + 1;
    };
    @print(acc);
    return i;
}
fn evens(limit: i32) -> i32 {
    var i = 0;
    var sum = 0;
    loop (i < limit) {
        i = i + 1;
        if (i % 2 == 1) { continue; };
        sum = sum + i;
    };
    return sum;
}
fn main() {
    @print(count(4));
    @print(count(0));
    @print(evens(6));
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\00\00\00\00")
  (global $__heap_ptr (mut i32) (i32.const 260))
  (func $count (param $limit i32) (result i32)
    (local $i i32)
    (local $acc i32)
    i32.const 0
    local.set $i
    i32.const 256
    local.set $acc
    (block $__break
      (loop $__continue
    local.get $i
    local.get $limit
    i32.lt_s
        i32.eqz
        br_if $__break
    local.get $acc
    local.get $i
    call $__i32_to_str
    call $__str_concat
    local.set $acc
    local.get $i
    i32.const 1
    i32.add
    local.set $i
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $acc
    call $__print_str
    local.get $i
    return
  )
  (func $evens (param $limit i32) (result i32)
    (local $i i32)
    (local $sum i32)
    i32.const 0
    local.set $i
    i32.const 0
    local.set $sum
    (block $__break
      (loop $__continue
    local.get $i
    local.get $limit
    i32.lt_s
        i32.eqz
        br_if $__break
        (block $__next
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    local.get $i
    i32.const 2
    i32.rem_s
    i32.const 1
    i32.eq
    (if (result i32)
      (then
    br $__next
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $sum
    local.get $i
    i32.add
    local.set $sum
        )
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $sum
    return
  )
  (func $main
    i32.const 4
    call $count
    call $__print_i32
    i32.const 0
    call $count
    call $__print_i32
    i32.const 6
    call $evens
    call $__print_i32
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
  (func $__print_str_raw (param $s i32)
    local.get $s
    i32.const 4
    i32.add
    local.get $s
    i32.load
    call $__write_bytes
  )
  (func $__print_str (param $s i32)
    local.get $s
    call $__print_str_raw
    call $__print_nl
  )
  (func $__str_concat (param $a i32) (param $b i32) (result i32)
    (local $base i32) (local $alen i32) (local $blen i32)
    local.get $a
    i32.load
    local.set $alen
    local.get $b
    i32.load
    local.set $blen
    global.get $__heap_ptr
    local.set $base
    ;; bump heap by 4 (length prefix) + alen + blen
    global.get $__heap_ptr
    i32.const 4
    local.get $alen
    i32.add
    local.get $blen
    i32.add
    i32.add
    global.set $__heap_ptr
    ;; store combined length prefix
    local.get $base
    local.get $alen
    local.get $blen
    i32.add
    i32.store
    ;; copy a's bytes: base+4 <- a+4
    local.get $base
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.add
    local.get $alen
    memory.copy
    ;; copy b's bytes: base+4+alen <- b+4
    local.get $base
    i32.const 4
    i32.add
    local.get $alen
    i32.add
    local.get $b
    i32.const 4
    i32.add
    local.get $blen
    memory.copy
    local.get $base
  )
  (func $__alloc (param $n i32) (result i32)
    (local $p i32)
    global.get $__heap_ptr
    local.set $p
    global.get $__heap_ptr
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    global.set $__heap_ptr
    local.get $p
  )
  (func $__i32_to_str (param $n i32) (result i32)
    (local $u i64) (local $pos i32) (local $len i32) (local $p i32) (local $neg i32)
    i32.const 160
    local.set $pos
    local.get $n
    i32.const 0
    i32.lt_s
    local.set $neg
    local.get $n
    i64.extend_i32_s
    local.set $u
    local.get $neg
    (if
      (then
        i64.const 0
        local.get $u
        i64.sub
        local.set $u
      )
    )
    (block $brk
      (loop $cont
        local.get $pos
        i32.const 1
        i32.sub
        local.set $pos
        local.get $pos
        local.get $u
        i64.const 10
        i64.rem_u
        i32.wrap_i64
        i32.const 48
        i32.add
        i32.store8
        local.get $u
        i64.const 10
        i64.div_u
        local.set $u
        local.get $u
        i64.eqz
        br_if $brk
        br $cont
      )
    )
    local.get $neg
    (if
      (then
        local.get $pos
        i32.const 1
        i32.sub
        local.set $pos
        local.get $pos
        i32.const 45
        i32.store8
      )
    )
    i32.const 160
    local.get $pos
    i32.sub
    local.set $len
    local.get $len
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $len
    i32.store
    local.get $p
    i32.const 4
    i32.add
    local.get $pos
    local.get $len
    memory.copy
    local.get $p
  )
)
```

----- RUN LOG -----
```logs
0123
4

0
12
```
