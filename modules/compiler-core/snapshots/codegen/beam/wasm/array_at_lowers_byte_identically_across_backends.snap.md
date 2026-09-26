----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print([10, 20].at(0));
    @print([10].at(5));
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $main
    (local $__mem0 i32)
    (local $__mem1 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 2
    i32.store
    local.get $__mem0
    i32.const 10
    i32.store offset=4
    local.get $__mem0
    i32.const 20
    i32.store offset=8
    local.get $__mem0
    i32.const 0
    call $__arr_at_box
    call $__print_opt_i32
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 1
    i32.store
    local.get $__mem1
    i32.const 10
    i32.store offset=4
    local.get $__mem1
    i32.const 5
    call $__arr_at_box
    call $__print_opt_i32
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
  (func $__print_bool (param $b i32)
    local.get $b
    call $__print_bool_raw
    call $__print_nl
  )
  (func $__print_bool_raw (param $b i32)
    local.get $b
    (if
      (then
        ;; "true" as a little-endian i32
        i32.const 16
        i32.const 1702195828
        i32.store
        i32.const 16
        i32.const 4
        call $__write_bytes
      )
      (else
        ;; "fals" + 'e'
        i32.const 16
        i32.const 1936482662
        i32.store
        i32.const 16
        i32.const 101
        i32.store8 offset=4
        i32.const 16
        i32.const 5
        call $__write_bytes
      )
    )
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
  (func $__box_i32 (param $v i32) (result i32)
    (local $p i32)
    i32.const 4
    call $__alloc
    local.set $p
    local.get $p
    local.get $v
    i32.store
    local.get $p
  )
  (func $__arr_at_box (param $xs i32) (param $i i32) (result i32)
    local.get $i
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $i
        local.get $xs
        i32.load
        i32.add
        local.set $i
      )
    )
    local.get $i
    i32.const 0
    i32.lt_s
    local.get $i
    local.get $xs
    i32.load
    i32.ge_s
    i32.or
    (if
      (then
        i32.const 0
        return
      )
    )
    local.get $xs
    i32.const 4
    i32.add
    local.get $i
    i32.const 4
    i32.mul
    i32.add
    i32.load
    call $__box_i32
  )
  (func $__print_null
    i32.const 176
    i32.const 1819047278
    i32.store
    i32.const 176
    i32.const 4
    call $__write_bytes
  )
  (func $__print_opt_i32_raw (param $p i32)
    local.get $p
    i32.eqz
    (if
      (then
        call $__print_null
      )
      (else
        local.get $p
        i32.load
        call $__print_i32_raw
      )
    )
  )
  (func $__print_opt_i32 (param $p i32)
    local.get $p
    call $__print_opt_i32_raw
    call $__print_nl
  )
  (func $__print_opt_bool_raw (param $p i32)
    local.get $p
    i32.eqz
    (if
      (then
        call $__print_null
      )
      (else
        local.get $p
        i32.load
        call $__print_bool_raw
      )
    )
  )
  (func $__print_opt_bool (param $p i32)
    local.get $p
    call $__print_opt_bool_raw
    call $__print_nl
  )
  (func $__print_opt_str_raw (param $s i32)
    local.get $s
    i32.eqz
    (if
      (then
        call $__print_null
      )
      (else
        local.get $s
        call $__print_str_raw
      )
    )
  )
  (func $__print_opt_str (param $s i32)
    local.get $s
    call $__print_opt_str_raw
    call $__print_nl
  )
)
```

----- RUN LOG -----
```logs
10
null
```
