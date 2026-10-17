----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print("aB".toUpper());
    @print("aB".toLower());
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
  )
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 304))
  (func $main
    (local $__gc0 (ref null $str))
    (local $__gc1 i32)
    (local $__gc2 (ref null $str))
    (local $__gc3 i32)
    global.get $__s0
    local.set $__gc0
    global.get $__heap_ptr
    local.set $__gc1
    local.get $__gc0
    call $__gc_to_lin_str
    call $__std_text_toUpper
    call $__lin_to_gc_str
    local.get $__gc1
    global.set $__heap_ptr
    call $__print_str
    global.get $__s0
    local.set $__gc2
    global.get $__heap_ptr
    local.set $__gc3
    local.get $__gc2
    call $__gc_to_lin_str
    call $__std_text_toLower
    call $__lin_to_gc_str
    local.get $__gc3
    global.set $__heap_ptr
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
  (func $__print_str_raw (param $s (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    local.get $s
    array.len
    local.set $n
    global.get $__heap_ptr
    local.set $top
    local.get $n
    call $__alloc
    local.set $p
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $s
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
    local.get $n
    call $__write_bytes
    local.get $top
    global.set $__heap_ptr
  )
  (func $__print_str (param $s (ref null $str))
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
  (func $__gc_to_lin_str (param $s (ref null $str)) (result i32)
    (local $n i32) (local $p i32) (local $i i32)
    local.get $s
    array.len
    local.set $n
    local.get $n
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $s
        local.get $i
        array.get_u $str
        i32.store8 offset=4
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
  )
  (func $__lin_to_gc_str (param $p i32) (result (ref null $str))
    (local $r (ref null $str)) (local $n i32) (local $i i32)
    local.get $p
    i32.load
    local.set $n
    local.get $n
    array.new_default $str
    local.set $r
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $r
        local.get $i
        local.get $p
        local.get $i
        i32.add
        i32.load8_u offset=4
        array.set $str
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $r
  )
  ;; std-wasm (decision 440): its functions, transpiled from std_wasm.wasm
  (global $__std_sp (mut i32) (i32.const 304))
  (func $__std_sp_check (param $sp i32) (result i32)
    local.get $sp
    i32.const 256
    i32.lt_s
    (if
      (then unreachable)
    )
    local.get $sp
  )
  ;; __std_f129 — from std_wasm.wasm (sha256 67dbdd61ea9b)
  ;; __std_f130 — from std_wasm.wasm (sha256 f15aa78ce6d6)
  ;; __std_f131 — from std_wasm.wasm (sha256 2f81dc7302bb)
  ;; __std_f132 — from std_wasm.wasm (sha256 38e98c1edeed)
  ;; __std_f133 — from std_wasm.wasm (sha256 16c99e1a095a)
  ;; __std_f134 — from std_wasm.wasm (sha256 30c514d3cfe8)
  ;; __std_f433 — from std_wasm.wasm (sha256 91fc3314249d)
  ;; std:text.toLower — from std_wasm.wasm (sha256 f43cfc9aef48)
  ;; __std_f498 — from std_wasm.wasm (sha256 60a80b3c5e19)
  ;; std:text.toUpper — from std_wasm.wasm (sha256 a2fe58c08ea4)
  (data $__d0 "aB")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 2
    array.new_data $str $__d0
    global.set $__s0
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
AB
ab
```
