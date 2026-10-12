----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "Hello,World";
    @print(s.toUpper());
    @print(s.toLower());
    @print(s.split(",").join("|"));
    @print(s.slice(0, 5));
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\0b\00\00\00Hello,World")
  (data (i32.const 272) "\01\00\00\00,")
  (data (i32.const 280) "\01\00\00\00|")
  (global $__heap_ptr (mut i32) (i32.const 1440))
  (func $main
    (local $s i32)
    i32.const 256
    local.set $s
    local.get $s
    call $__std_text_toUpper
    call $__print_str
    local.get $s
    call $__std_text_toLower
    call $__print_str
    local.get $s
    i32.const 272
    call $__std_text_split
    i32.const 280
    call $__std_array_joinStrings
    call $__print_str
    local.get $s
    i32.const 0
    i32.const 5
    call $__std_text_slice
    call $__print_str
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
  (func $__print_str_raw (param $s i32)
    local.get $s
    i32.const 256
    i32.lt_u
    (if
      (then
        ;; a pointer below the data floor is not a string
        unreachable
      )
    )
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
  ;; std-wasm (decision 440): its functions, transpiled from std_wasm.wasm
  (global $__std_sp (mut i32) (i32.const 1440))
  (func $__std_sp_check (param $sp i32) (result i32)
    local.get $sp
    i32.const 288
    i32.lt_s
    (if
      (then unreachable)
    )
    local.get $sp
  )
  ;; __std_f4 — from std_wasm.wasm (sha256 b4b6f06748d6)
  ;; __std_f21 — from std_wasm.wasm (sha256 61b86fc4b3a0)
  ;; __std_f23 — from std_wasm.wasm (sha256 2448159130cb)
  ;; __std_f86 — from std_wasm.wasm (sha256 a384dc7f28cf)
  ;; __std_f89 — from std_wasm.wasm (sha256 92db5f8bc6ab)
  ;; __std_f127 — from std_wasm.wasm (sha256 4e3aa0ae5882)
  ;; __std_f128 — from std_wasm.wasm (sha256 0d1b11b49ccf)
  ;; __std_f129 — from std_wasm.wasm (sha256 2f81dc7302bb)
  ;; __std_f130 — from std_wasm.wasm (sha256 38e98c1edeed)
  ;; __std_f131 — from std_wasm.wasm (sha256 16c99e1a095a)
  ;; __std_f132 — from std_wasm.wasm (sha256 30c514d3cfe8)
  ;; __std_f263 — from std_wasm.wasm (sha256 5ac39cdc3016)
  ;; __std_f264 — from std_wasm.wasm (sha256 cda2fb2bf3e4)
  ;; __std_f353 — from std_wasm.wasm (sha256 91fc3314249d)
  ;; __std_f369 — from std_wasm.wasm (sha256 d13a98c08300)
  ;; std:array.joinStrings — from std_wasm.wasm (sha256 584a2fd22ad9)
  ;; std:text.slice — from std_wasm.wasm (sha256 e7f2bbc02fae)
  ;; std:text.toLower — from std_wasm.wasm (sha256 86e907efaeaa)
  ;; __std_f407 — from std_wasm.wasm (sha256 8f8ae3c9376e)
  ;; std:text.toUpper — from std_wasm.wasm (sha256 41be1235659b)
  ;; __std_f427 — from std_wasm.wasm (sha256 0636b028558a)
  ;; std:text.split — from std_wasm.wasm (sha256 44268abc8922)
)
```

----- RUN LOG -----
```logs
HELLO,WORLD
hello,world
Hello|World
Hello
```
