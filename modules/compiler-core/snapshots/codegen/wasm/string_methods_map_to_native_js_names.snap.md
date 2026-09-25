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
  (global $__heap_ptr (mut i32) (i32.const 288))
  (func $main
    (local $s i32)
    i32.const 256
    local.set $s
    local.get $s
    i32.const 97
    i32.const 122
    i32.const -32
    call $__str_case
    call $__print_str
    local.get $s
    i32.const 65
    i32.const 90
    i32.const 32
    call $__str_case
    call $__print_str
    local.get $s
    i32.const 272
    call $__str_split
    i32.const 280
    call $__arr_join_str
    call $__print_str
    local.get $s
    i32.const 0
    i32.const 5
    call $__str_slice
    call $__print_str
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
  (func $__str_slice (param $src i32) (param $start i32) (param $end i32) (result i32)
    (local $newlen i32) (local $dst i32)
    local.get $end
    local.get $start
    i32.sub
    local.set $newlen
    global.get $__heap_ptr
    local.set $dst
    ;; bump heap by 4 (length prefix) + newlen
    global.get $__heap_ptr
    i32.const 4
    local.get $newlen
    i32.add
    i32.add
    global.set $__heap_ptr
    ;; store length prefix
    local.get $dst
    local.get $newlen
    i32.store
    ;; copy bytes: dst+4 <- src+4+start
    local.get $dst
    i32.const 4
    i32.add
    local.get $src
    i32.const 4
    i32.add
    local.get $start
    i32.add
    local.get $newlen
    memory.copy
    local.get $dst
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
  (func $__mem_eq (param $a i32) (param $b i32) (param $n i32) (result i32)
    (local $i i32)
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $a
        local.get $i
        i32.add
        i32.load8_u
        local.get $b
        local.get $i
        i32.add
        i32.load8_u
        i32.ne
        (if
          (then
            i32.const 0
            return
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    i32.const 1
  )
  (func $__str_case (param $s i32) (param $lo i32) (param $hi i32) (param $delta i32) (result i32)
    (local $n i32) (local $p i32) (local $i i32) (local $ch i32)
    local.get $s
    i32.load
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
        local.get $s
        local.get $i
        i32.add
        i32.load8_u offset=4
        local.set $ch
        local.get $ch
        local.get $lo
        i32.ge_u
        local.get $ch
        local.get $hi
        i32.le_u
        i32.and
        (if
          (then
            local.get $ch
            local.get $delta
            i32.add
            local.set $ch
          )
        )
        local.get $p
        local.get $i
        i32.add
        local.get $ch
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
  (func $__str_split (param $s i32) (param $sep i32) (result i32)
    (local $n i32) (local $m i32) (local $i i32) (local $cnt i32) (local $arr i32) (local $start i32) (local $k i32)
    local.get $s
    i32.load
    local.set $n
    local.get $sep
    i32.load
    local.set $m
    local.get $m
    i32.eqz
    (if
      (then
        local.get $n
        call $__arr_new
        local.set $arr
        (block $brk
          (loop $cont
            local.get $i
            local.get $n
            i32.ge_u
            br_if $brk
            local.get $arr
            i32.const 4
            i32.add
            local.get $i
            i32.const 4
            i32.mul
            i32.add
            local.get $s
            local.get $i
            local.get $i
            i32.const 1
            i32.add
            call $__str_slice
            i32.store
            local.get $i
            i32.const 1
            i32.add
            local.set $i
            br $cont
          )
        )
        local.get $arr
        return
      )
    )
    i32.const 1
    local.set $cnt
    (block $brk
      (loop $cont
        local.get $i
        local.get $m
        i32.add
        local.get $n
        i32.gt_u
        br_if $brk
        local.get $s
        i32.const 4
        i32.add
        local.get $i
        i32.add
        local.get $sep
        i32.const 4
        i32.add
        local.get $m
        call $__mem_eq
        (if
          (then
            local.get $cnt
            i32.const 1
            i32.add
            local.set $cnt
            local.get $i
            local.get $m
            i32.add
            local.set $i
          )
          (else
            local.get $i
            i32.const 1
            i32.add
            local.set $i
          )
        )
        br $cont
      )
    )
    local.get $cnt
    call $__arr_new
    local.set $arr
    i32.const 0
    local.set $i
    (block $brk
      (loop $cont
        local.get $i
        local.get $m
        i32.add
        local.get $n
        i32.gt_u
        br_if $brk
        local.get $s
        i32.const 4
        i32.add
        local.get $i
        i32.add
        local.get $sep
        i32.const 4
        i32.add
        local.get $m
        call $__mem_eq
        (if
          (then
            local.get $arr
            i32.const 4
            i32.add
            local.get $k
            i32.const 4
            i32.mul
            i32.add
            local.get $s
            local.get $start
            local.get $i
            call $__str_slice
            i32.store
            local.get $k
            i32.const 1
            i32.add
            local.set $k
            local.get $i
            local.get $m
            i32.add
            local.tee $i
            local.set $start
          )
          (else
            local.get $i
            i32.const 1
            i32.add
            local.set $i
          )
        )
        br $cont
      )
    )
    local.get $arr
    i32.const 4
    i32.add
    local.get $k
    i32.const 4
    i32.mul
    i32.add
    local.get $s
    local.get $start
    local.get $n
    call $__str_slice
    i32.store
    local.get $arr
  )
  (func $__arr_new (param $n i32) (result i32)
    (local $p i32)
    local.get $n
    i32.const 1
    i32.add
    i32.const 4
    i32.mul
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
    local.get $p
  )
  (func $__arr_join_str (param $xs i32) (param $sep i32) (result i32)
    (local $n i32) (local $i i32) (local $total i32) (local $p i32) (local $pos i32) (local $e i32)
    local.get $xs
    i32.load
    local.set $n
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $total
        local.get $xs
        i32.const 4
        i32.add
        local.get $i
        i32.const 4
        i32.mul
        i32.add
        i32.load
        i32.load
        i32.add
        local.set $total
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $n
    (if
      (then
        local.get $total
        local.get $sep
        i32.load
        local.get $n
        i32.const 1
        i32.sub
        i32.mul
        i32.add
        local.set $total
      )
    )
    local.get $total
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $total
    i32.store
    local.get $p
    i32.const 4
    i32.add
    local.set $pos
    i32.const 0
    local.set $i
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $i
        (if
          (then
            local.get $pos
            local.get $sep
            i32.const 4
            i32.add
            local.get $sep
            i32.load
            memory.copy
            local.get $pos
            local.get $sep
            i32.load
            i32.add
            local.set $pos
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
        local.set $e
        local.get $pos
        local.get $e
        i32.const 4
        i32.add
        local.get $e
        i32.load
        memory.copy
        local.get $pos
        local.get $e
        i32.load
        i32.add
        local.set $pos
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
  )
)
```

----- RUN LOG -----
```logs
HELLO,WORLD
hello,world
Hello|World
Hello
```
