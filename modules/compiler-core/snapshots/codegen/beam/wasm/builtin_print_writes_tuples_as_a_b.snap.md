----- SOURCE CODE -- main.bp
```botopink
fn pairOf(a: i32, b: string) -> #(i32, string) {
    return #(a, b);
}
fn show(p: #(i32, string)) {
    @print(p);
}
fn main() {
    @print(#(true, 1));
    @print(#(#(1, 2), "x"));
    @print([#(1, 2), #(17, 1)]);
    @print(pairOf(7, "s"));
    show(#(3, "z"));
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\04\00\00\00(is)")
  (data (i32.const 264) "\04\00\00\00(bi)")
  (data (i32.const 272) "\01\00\00\00x")
  (data (i32.const 280) "\07\00\00\00((ii)s)")
  (data (i32.const 292) "\05\00\00\00[(ii)")
  (data (i32.const 304) "\01\00\00\00s")
  (data (i32.const 312) "\01\00\00\00z")
  (global $__heap_ptr (mut i32) (i32.const 320))
  (func $pairOf (param $a i32) (param $b i32) (result i32)
    (local $__mem0 i32)
    i32.const 8
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    local.get $a
    i32.store
    local.get $__mem0
    local.get $b
    i32.store offset=4
    local.get $__mem0
    return
  )
  (func $show (param $p i32)
    local.get $p
    i32.const 260
    i32.const 1
    call $__print_shaped_raw
    drop
    call $__print_nl
  )
  (func $main (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    (local $__mem5 i32)
    (local $__mem6 i32)
    i32.const 8
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 1
    i32.store
    local.get $__mem0
    i32.const 1
    i32.store offset=4
    local.get $__mem0
    i32.const 268
    i32.const 1
    call $__print_shaped_raw
    drop
    call $__print_nl
    i32.const 8
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 8
    call $__alloc
    local.set $__mem2
    local.get $__mem2
    i32.const 1
    i32.store
    local.get $__mem2
    i32.const 2
    i32.store offset=4
    local.get $__mem2
    i32.store
    local.get $__mem1
    i32.const 272
    i32.store offset=4
    local.get $__mem1
    i32.const 284
    i32.const 1
    call $__print_shaped_raw
    drop
    call $__print_nl
    i32.const 12
    call $__alloc
    local.set $__mem3
    local.get $__mem3
    i32.const 2
    i32.store
    local.get $__mem3
    i32.const 8
    call $__alloc
    local.set $__mem4
    local.get $__mem4
    i32.const 1
    i32.store
    local.get $__mem4
    i32.const 2
    i32.store offset=4
    local.get $__mem4
    i32.store offset=4
    local.get $__mem3
    i32.const 8
    call $__alloc
    local.set $__mem5
    local.get $__mem5
    i32.const 17
    i32.store
    local.get $__mem5
    i32.const 1
    i32.store offset=4
    local.get $__mem5
    i32.store offset=8
    local.get $__mem3
    i32.const 296
    i32.const 1
    call $__print_shaped_raw
    drop
    call $__print_nl
    i32.const 7
    i32.const 304
    call $pairOf
    i32.const 260
    i32.const 1
    call $__print_shaped_raw
    drop
    call $__print_nl
    i32.const 8
    call $__alloc
    local.set $__mem6
    local.get $__mem6
    i32.const 3
    i32.store
    local.get $__mem6
    i32.const 312
    i32.store offset=4
    local.get $__mem6
    call $show
    i32.const 0
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
    drop
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
  (func $__print_f64 (param $x f64)
    local.get $x
    call $__print_f64_raw
    call $__print_nl
  )
  (func $__print_f64_raw (param $x f64)
    (local $n i32)
    local.get $x
    i32.const 1
    call $__f64_fmt
    local.set $n
    call $__dtoa_ws
    i32.const 832
    i32.add
    local.get $n
    call $__write_bytes
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
  (func $__print_quoted_raw (param $s i32)
    (local $n i32) (local $i i32) (local $ch i32) (local $e i32)
    i32.const 8
    i32.const 34
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
    local.get $s
    i32.load
    local.set $n
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $s
        i32.const 4
        i32.add
        local.get $i
        i32.add
        i32.load8_u
        local.set $ch
        i32.const 0
        local.set $e
        local.get $ch
        i32.const 34
        i32.eq
        local.get $ch
        i32.const 92
        i32.eq
        i32.or
        (if
          (then
            local.get $ch
            local.set $e
          )
        )
        local.get $ch
        i32.const 10
        i32.eq
        (if
          (then
            i32.const 110
            local.set $e
          )
        )
        local.get $ch
        i32.const 13
        i32.eq
        (if
          (then
            i32.const 114
            local.set $e
          )
        )
        local.get $ch
        i32.const 9
        i32.eq
        (if
          (then
            i32.const 116
            local.set $e
          )
        )
        local.get $e
        (if
          (then
            i32.const 8
            i32.const 92
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
            i32.const 8
            local.get $e
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
          )
          (else
            i32.const 8
            local.get $ch
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    i32.const 8
    i32.const 34
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_tagged_raw (param $v i32)
    (local $d i32) (local $p i32) (local $k i32) (local $i i32) (local $n i32) (local $b i32) (local $s i32)
    local.get $v
    call $__display_of
    local.set $s
    local.get $s
    (if
      (then
        local.get $s
        i32.const 4
        i32.add
        local.get $s
        i32.load
        call $__write_bytes
        return
      )
    )
    local.get $v
    i32.const 4
    i32.sub
    i32.load
    local.set $d
    local.get $d
    i32.const 1
    i32.add
    local.set $p
    local.get $v
    local.set $b
    local.get $d
    i32.load8_u
    i32.const 86
    i32.eq
    (if
      (then
        local.get $v
        i32.const 4
        i32.add
        local.set $b
      )
    )
    local.get $p
    i32.load8_u
    local.set $n
    local.get $p
    i32.const 1
    i32.add
    local.set $p
    local.get $p
    local.get $n
    call $__write_bytes
    local.get $p
    local.get $n
    i32.add
    local.set $p
    local.get $p
    i32.load8_u
    local.set $k
    local.get $p
    i32.const 1
    i32.add
    local.set $p
    local.get $k
    (if
      (then
        i32.const 8
        i32.const 40
        i32.store8
        i32.const 8
        i32.const 1
        call $__write_bytes
      )
    )
    (block $brk
      (loop $cont
        local.get $i
        local.get $k
        i32.ge_u
        br_if $brk
        local.get $i
        (if
          (then
            i32.const 8
            i32.const 44
            i32.store8
            i32.const 8
            i32.const 32
            i32.store8 offset=1
            i32.const 8
            i32.const 2
            call $__write_bytes
          )
        )
        local.get $p
        i32.load8_u
        local.set $n
        local.get $p
        i32.const 1
        i32.add
        local.set $p
        local.get $p
        local.get $n
        call $__write_bytes
        local.get $p
        local.get $n
        i32.add
        local.set $p
        i32.const 8
        i32.const 58
        i32.store8
        i32.const 8
        i32.const 32
        i32.store8 offset=1
        i32.const 8
        i32.const 2
        call $__write_bytes
        local.get $b
        i32.const 4
        i32.add
        local.get $i
        i32.const 4
        i32.mul
        i32.add
        i32.const 4
        i32.sub
        i32.load
        local.get $p
        i32.const 1
        call $__print_shaped_raw
        local.set $p
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $k
    (if
      (then
        i32.const 8
        i32.const 41
        i32.store8
        i32.const 8
        i32.const 1
        call $__write_bytes
      )
    )
  )
  (func $__print_tagged (param $v i32)
    local.get $v
    call $__print_tagged_raw
    call $__print_nl
  )
  (func $__print_shaped_raw (param $v i32) (param $sh i32) (param $go i32) (result i32)
    (local $c i32) (local $n i32) (local $i i32) (local $p i32) (local $e i32)
    local.get $sh
    i32.load8_u
    local.set $c
    local.get $c
    i32.const 105
    i32.eq
    (if
      (then
        local.get $go
        (if
          (then
            local.get $v
            call $__print_i32_raw
          )
        )
        local.get $sh
        i32.const 1
        i32.add
        return
      )
    )
    local.get $c
    i32.const 98
    i32.eq
    (if
      (then
        local.get $go
        (if
          (then
            local.get $v
            call $__print_bool_raw
          )
        )
        local.get $sh
        i32.const 1
        i32.add
        return
      )
    )
    local.get $c
    i32.const 102
    i32.eq
    (if
      (then
        local.get $go
        (if
          (then
            local.get $v
            f64.load
            call $__print_f64_raw
          )
        )
        local.get $sh
        i32.const 1
        i32.add
        return
      )
    )
    local.get $c
    i32.const 108
    i32.eq
    (if
      (then
        local.get $go
        (if
          (then
            local.get $v
            i64.load
            call $__print_i64_raw
          )
        )
        local.get $sh
        i32.const 1
        i32.add
        return
      )
    )
    local.get $c
    i32.const 115
    i32.eq
    (if
      (then
        local.get $go
        (if
          (then
            local.get $v
            call $__print_quoted_raw
          )
        )
        local.get $sh
        i32.const 1
        i32.add
        return
      )
    )
    local.get $c
    i32.const 84
    i32.eq
    (if
      (then
        local.get $go
        (if
          (then
            local.get $v
            call $__print_tagged_raw
          )
        )
        local.get $sh
        i32.const 1
        i32.add
        return
      )
    )
    local.get $c
    i32.const 91
    i32.eq
    (if
      (then
        local.get $go
        (if
          (then
            i32.const 8
            i32.const 91
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
          )
        )
        local.get $sh
        i32.const 1
        i32.add
        local.set $e
        i32.const 0
        local.get $e
        i32.const 0
        call $__print_shaped_raw
        local.set $p
        local.get $go
        (if
          (then
            local.get $v
            i32.load
            local.set $n
          )
        )
        (block $brk
          (loop $cont
            local.get $i
            local.get $n
            i32.ge_u
            br_if $brk
            local.get $i
            (if
              (then
                i32.const 8
                i32.const 44
                i32.store8
                i32.const 8
                i32.const 32
                i32.store8 offset=1
                i32.const 8
                i32.const 2
                call $__write_bytes
              )
            )
            local.get $v
            i32.const 4
            i32.add
            local.get $i
            i32.const 4
            i32.mul
            i32.add
            i32.load
            local.get $e
            i32.const 1
            call $__print_shaped_raw
            drop
            local.get $i
            i32.const 1
            i32.add
            local.set $i
            br $cont
          )
        )
        local.get $go
        (if
          (then
            i32.const 8
            i32.const 93
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
          )
        )
        local.get $p
        return
      )
    )
    local.get $c
    i32.const 69
    i32.eq
    (if
      (then
        local.get $sh
        i32.const 1
        i32.add
        i32.load8_u
        local.set $n
        local.get $sh
        i32.const 2
        i32.add
        local.set $p
        (block $brk
          (loop $cont
            local.get $i
            local.get $n
            i32.ge_u
            br_if $brk
            local.get $go
            (if
              (then
                local.get $i
                local.get $v
                i32.eq
                (if
                  (then
                    local.get $p
                    i32.const 1
                    i32.add
                    local.get $p
                    i32.load8_u
                    call $__write_bytes
                  )
                )
              )
            )
            local.get $p
            local.get $p
            i32.load8_u
            i32.add
            i32.const 1
            i32.add
            local.set $p
            local.get $i
            i32.const 1
            i32.add
            local.set $i
            br $cont
          )
        )
        local.get $p
        return
      )
    )
    local.get $c
    i32.const 40
    i32.eq
    (if
      (then
        local.get $go
        (if
          (then
            i32.const 8
            i32.const 35
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
            i32.const 8
            i32.const 40
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
          )
        )
        local.get $sh
        i32.const 1
        i32.add
        local.set $p
        (block $brk
          (loop $cont
            local.get $p
            i32.load8_u
            i32.const 41
            i32.eq
            br_if $brk
            local.get $go
            (if
              (then
                local.get $i
                (if
                  (then
                    i32.const 8
                    i32.const 44
                    i32.store8
                    i32.const 8
                    i32.const 32
                    i32.store8 offset=1
                    i32.const 8
                    i32.const 2
                    call $__write_bytes
                  )
                )
              )
            )
            local.get $v
            local.get $i
            i32.const 4
            i32.mul
            i32.add
            i32.load
            local.get $p
            local.get $go
            call $__print_shaped_raw
            local.set $p
            local.get $i
            i32.const 1
            i32.add
            local.set $i
            br $cont
          )
        )
        local.get $go
        (if
          (then
            i32.const 8
            i32.const 41
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
          )
        )
        local.get $p
        i32.const 1
        i32.add
        return
      )
    )
    local.get $sh
    i32.const 1
    i32.add
  )
  (func $__display_of (param $v i32) (result i32)
    i32.const 0
  )
  (global $__dtoa_ws (mut i32) (i32.const 0))
  (func $__dtoa_ws (result i32)
    global.get $__dtoa_ws
    i32.eqz
    (if
      (then
        i32.const 920
        call $__alloc
        global.set $__dtoa_ws
      )
    )
    global.get $__dtoa_ws
  )
  (func $__big_set (param $a i32) (param $v i64)
    (local $i i32)
    (block $brk
      (loop $cont
        local.get $i
        i32.const 160
        i32.ge_u
        br_if $brk
        local.get $a
        local.get $i
        i32.add
        i32.const 0
        i32.store
        local.get $i
        i32.const 4
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $a
    local.get $v
    i32.wrap_i64
    i32.store
    local.get $a
    local.get $v
    i64.const 32
    i64.shr_u
    i32.wrap_i64
    i32.store offset=4
  )
  (func $__big_mul (param $a i32) (param $m i64)
    (local $i i32) (local $t i64) (local $c i64)
    (block $brk
      (loop $cont
        local.get $i
        i32.const 160
        i32.ge_u
        br_if $brk
        local.get $a
        local.get $i
        i32.add
        i32.load
        i64.extend_i32_u
        local.get $m
        i64.mul
        local.get $c
        i64.add
        local.set $t
        local.get $a
        local.get $i
        i32.add
        local.get $t
        i32.wrap_i64
        i32.store
        local.get $t
        i64.const 32
        i64.shr_u
        local.set $c
        local.get $i
        i32.const 4
        i32.add
        local.set $i
        br $cont
      )
    )
  )
  (func $__big_add (param $a i32) (param $b i32)
    (local $i i32) (local $t i64) (local $c i64)
    (block $brk
      (loop $cont
        local.get $i
        i32.const 160
        i32.ge_u
        br_if $brk
        local.get $a
        local.get $i
        i32.add
        i32.load
        i64.extend_i32_u
        local.get $b
        local.get $i
        i32.add
        i32.load
        i64.extend_i32_u
        i64.add
        local.get $c
        i64.add
        local.set $t
        local.get $a
        local.get $i
        i32.add
        local.get $t
        i32.wrap_i64
        i32.store
        local.get $t
        i64.const 32
        i64.shr_u
        local.set $c
        local.get $i
        i32.const 4
        i32.add
        local.set $i
        br $cont
      )
    )
  )
  (func $__big_sub (param $a i32) (param $b i32)
    (local $i i32) (local $t i64) (local $c i64)
    (block $brk
      (loop $cont
        local.get $i
        i32.const 160
        i32.ge_u
        br_if $brk
        local.get $a
        local.get $i
        i32.add
        i32.load
        i64.extend_i32_u
        local.get $b
        local.get $i
        i32.add
        i32.load
        i64.extend_i32_u
        i64.sub
        local.get $c
        i64.sub
        local.set $t
        local.get $a
        local.get $i
        i32.add
        local.get $t
        i32.wrap_i64
        i32.store
        local.get $t
        i64.const 63
        i64.shr_u
        local.set $c
        local.get $i
        i32.const 4
        i32.add
        local.set $i
        br $cont
      )
    )
  )
  (func $__big_cmp (param $a i32) (param $b i32) (result i32)
    (local $i i32) (local $x i32) (local $y i32)
    i32.const 160
    local.set $i
    (block $brk
      (loop $cont
        local.get $i
        i32.eqz
        br_if $brk
        local.get $i
        i32.const 4
        i32.sub
        local.set $i
        local.get $a
        local.get $i
        i32.add
        i32.load
        local.set $x
        local.get $b
        local.get $i
        i32.add
        i32.load
        local.set $y
        local.get $x
        local.get $y
        i32.lt_u
        (if
          (then
            i32.const -1
            return
          )
        )
        local.get $x
        local.get $y
        i32.gt_u
        (if
          (then
            i32.const 1
            return
          )
        )
        br $cont
      )
    )
    i32.const 0
  )
  (func $__big_pcmp (param $a i32) (param $b i32) (param $c i32) (param $t i32) (result i32)
    local.get $t
    local.get $a
    i32.const 160
    memory.copy
    local.get $t
    local.get $b
    call $__big_add
    local.get $t
    local.get $c
    call $__big_cmp
  )
  (func $__big_shl (param $a i32) (param $n i32)
    (block $brk
      (loop $cont
        local.get $n
        i32.const 31
        i32.lt_s
        br_if $brk
        local.get $a
        i64.const 2147483648
        call $__big_mul
        local.get $n
        i32.const 31
        i32.sub
        local.set $n
        br $cont
      )
    )
    local.get $a
    i64.const 1
    local.get $n
    i64.extend_i32_u
    i64.shl
    call $__big_mul
  )
  (func $__big_pow10 (param $a i32) (param $n i32)
    (block $brk
      (loop $cont
        local.get $n
        i32.const 9
        i32.lt_s
        br_if $brk
        local.get $a
        i64.const 1000000000
        call $__big_mul
        local.get $n
        i32.const 9
        i32.sub
        local.set $n
        br $cont
      )
    )
    (block $brk
      (loop $cont
        local.get $n
        i32.eqz
        br_if $brk
        local.get $a
        i64.const 10
        call $__big_mul
        local.get $n
        i32.const 1
        i32.sub
        local.set $n
        br $cont
      )
    )
  )
  (func $__dtoa (param $v f64) (result i32)
    (local $w i32) (local $n i32) (local $d i32) (local $m i32) (local $p i32) (local $t i32) (local $bexp i32) (local $e i32) (local $ne i32) (local $near i32) (local $even i32) (local $k i32) (local $len i32) (local $dig i32) (local $lo i32) (local $hi i32) (local $cc i32) (local $bits i64) (local $mant i64) (local $f i64) (local $nf i64)
    call $__dtoa_ws
    local.tee $w
    local.set $n
    local.get $w
    i32.const 160
    i32.add
    local.set $d
    local.get $w
    i32.const 320
    i32.add
    local.set $m
    local.get $w
    i32.const 480
    i32.add
    local.set $p
    local.get $w
    i32.const 640
    i32.add
    local.set $t
    local.get $v
    i64.reinterpret_f64
    local.set $bits
    local.get $bits
    i64.const 52
    i64.shr_u
    i32.wrap_i64
    i32.const 2047
    i32.and
    local.set $bexp
    local.get $bits
    i64.const 4503599627370495
    i64.and
    local.set $mant
    local.get $bexp
    i32.eqz
    (if
      (then
        local.get $mant
        local.set $f
        i32.const -1074
        local.set $e
      )
      (else
        local.get $mant
        i64.const 4503599627370496
        i64.or
        local.set $f
        local.get $bexp
        i32.const 1075
        i32.sub
        local.set $e
      )
    )
    local.get $mant
    i64.eqz
    local.get $bexp
    i32.const 1
    i32.gt_s
    i32.and
    local.set $near
    local.get $f
    i64.const 1
    i64.and
    i64.eqz
    local.set $even
    local.get $f
    local.set $nf
    local.get $e
    local.set $ne
    (block $brk
      (loop $cont
        local.get $nf
        i64.const 4503599627370496
        i64.and
        i64.eqz
        i32.eqz
        br_if $brk
        local.get $nf
        i64.const 1
        i64.shl
        local.set $nf
        local.get $ne
        i32.const 1
        i32.sub
        local.set $ne
        br $cont
      )
    )
    local.get $ne
    i32.const 52
    i32.add
    f64.convert_i32_s
    f64.const 0.30102999566398114
    f64.mul
    f64.const 1e-10
    f64.sub
    f64.ceil
    i32.trunc_f64_s
    local.set $k
    local.get $e
    i32.const 0
    i32.ge_s
    (if
      (then
        local.get $n
        local.get $f
        call $__big_set
        local.get $n
        local.get $e
        i32.const 1
        i32.add
        call $__big_shl
        local.get $d
        i64.const 1
        call $__big_set
        local.get $d
        local.get $k
        call $__big_pow10
        local.get $d
        i32.const 1
        call $__big_shl
        local.get $p
        i64.const 1
        call $__big_set
        local.get $p
        local.get $e
        call $__big_shl
        local.get $m
        i64.const 1
        call $__big_set
        local.get $m
        local.get $e
        call $__big_shl
      )
      (else
        local.get $k
        i32.const 0
        i32.ge_s
        (if
          (then
            local.get $n
            local.get $f
            call $__big_set
            local.get $n
            i32.const 1
            call $__big_shl
            local.get $d
            i64.const 1
            call $__big_set
            local.get $d
            local.get $k
            call $__big_pow10
            local.get $d
            i32.const 1
            local.get $e
            i32.sub
            call $__big_shl
            local.get $p
            i64.const 1
            call $__big_set
            local.get $m
            i64.const 1
            call $__big_set
          )
          (else
            local.get $p
            i64.const 1
            call $__big_set
            local.get $p
            i32.const 0
            local.get $k
            i32.sub
            call $__big_pow10
            local.get $m
            local.get $p
            i32.const 160
            memory.copy
            local.get $n
            local.get $f
            call $__big_set
            local.get $n
            i32.const 0
            local.get $k
            i32.sub
            call $__big_pow10
            local.get $n
            i32.const 1
            call $__big_shl
            local.get $d
            i64.const 1
            call $__big_set
            local.get $d
            i32.const 1
            local.get $e
            i32.sub
            call $__big_shl
          )
        )
      )
    )
    local.get $near
    (if
      (then
        local.get $n
        i32.const 1
        call $__big_shl
        local.get $d
        i32.const 1
        call $__big_shl
        local.get $p
        i32.const 1
        call $__big_shl
      )
    )
    local.get $n
    local.get $p
    local.get $d
    local.get $t
    call $__big_pcmp
    local.get $even
    i32.add
    i32.const 0
    i32.gt_s
    (if
      (then
        local.get $k
        i32.const 1
        i32.add
        local.set $k
      )
      (else
        local.get $n
        i64.const 10
        call $__big_mul
        local.get $m
        i64.const 10
        call $__big_mul
        local.get $p
        i64.const 10
        call $__big_mul
      )
    )
    (block $gbrk
      (loop $gcont
        i32.const 0
        local.set $dig
        (block $brk
          (loop $cont
            local.get $n
            local.get $d
            call $__big_cmp
            i32.const 0
            i32.lt_s
            br_if $brk
            local.get $n
            local.get $d
            call $__big_sub
            local.get $dig
            i32.const 1
            i32.add
            local.set $dig
            br $cont
          )
        )
        local.get $w
        i32.const 804
        i32.add
        local.get $len
        i32.add
        local.get $dig
        i32.const 48
        i32.add
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
        local.get $n
        local.get $m
        call $__big_cmp
        local.get $even
        i32.lt_s
        local.set $lo
        local.get $n
        local.get $p
        local.get $d
        local.get $t
        call $__big_pcmp
        local.get $even
        i32.add
        i32.const 0
        i32.gt_s
        local.set $hi
        local.get $lo
        local.get $hi
        i32.or
        br_if $gbrk
        local.get $n
        i64.const 10
        call $__big_mul
        local.get $m
        i64.const 10
        call $__big_mul
        local.get $p
        i64.const 10
        call $__big_mul
        br $gcont
      )
    )
    local.get $lo
    local.get $hi
    i32.and
    (if
      (then
        local.get $n
        local.get $n
        local.get $d
        local.get $t
        call $__big_pcmp
        local.set $cc
        local.get $cc
        i32.const 0
        i32.gt_s
        local.get $cc
        i32.eqz
        local.get $dig
        i32.const 1
        i32.and
        i32.and
        i32.or
        local.set $hi
      )
    )
    local.get $hi
    (if
      (then
        local.get $w
        i32.const 803
        i32.add
        local.get $len
        i32.add
        local.tee $t
        local.get $t
        i32.load8_u
        i32.const 1
        i32.add
        i32.store8
      )
    )
    local.get $w
    local.get $k
    i32.store offset=800
    local.get $len
  )
  (func $__fmt_u64 (param $q i32) (param $v i64) (param $width i32) (result i32)
    (local $t i32) (local $cnt i32)
    call $__dtoa_ws
    i32.const 920
    i32.add
    local.set $t
    (block $brk
      (loop $cont
        local.get $t
        i32.const 1
        i32.sub
        local.set $t
        local.get $t
        local.get $v
        i64.const 10
        i64.rem_u
        i32.wrap_i64
        i32.const 48
        i32.add
        i32.store8
        local.get $v
        i64.const 10
        i64.div_u
        local.set $v
        local.get $cnt
        i32.const 1
        i32.add
        local.set $cnt
        local.get $v
        i64.eqz
        local.get $cnt
        local.get $width
        i32.ge_s
        i32.and
        br_if $brk
        br $cont
      )
    )
    local.get $q
    local.get $t
    local.get $cnt
    memory.copy
    local.get $q
    local.get $cnt
    i32.add
  )
  (func $__f64_fmt (param $x f64) (param $mode i32) (result i32)
    (local $w i32) (local $q i32) (local $len i32) (local $pt i32) (local $dig i32) (local $i i32) (local $e i32) (local $bits i64) (local $f i64) (local $a i64) (local $c i64)
    call $__dtoa_ws
    local.tee $w
    i32.const 832
    i32.add
    local.set $q
    local.get $x
    local.get $x
    f64.ne
    (if
      (then
        local.get $q
        i32.const 78
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
        local.get $q
        i32.const 97
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
        local.get $q
        i32.const 78
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
        local.get $q
        local.get $w
        i32.const 832
        i32.add
        i32.sub
        return
      )
    )
    local.get $mode
    local.get $x
    f64.floor
    local.get $x
    f64.eq
    i32.and
    local.get $x
    f64.abs
    f64.const 1e21
    f64.lt
    i32.and
    (if
      (then
        local.get $x
        f64.const 0
        f64.lt
        (if
          (then
            local.get $q
            i32.const 45
            i32.store8
            local.get $q
            i32.const 1
            i32.add
            local.set $q
            local.get $x
            f64.neg
            local.set $x
          )
        )
        local.get $x
        f64.const 9223372036854775808
        f64.lt
        (if
          (then
            local.get $q
            local.get $x
            i64.trunc_f64_s
            i32.const 1
            call $__fmt_u64
            local.set $q
          )
          (else
            local.get $x
            i64.reinterpret_f64
            local.set $bits
            local.get $bits
            i64.const 4503599627370495
            i64.and
            i64.const 4503599627370496
            i64.or
            local.set $f
            local.get $bits
            i64.const 52
            i64.shr_u
            i32.wrap_i64
            i32.const 1075
            i32.sub
            local.set $e
            local.get $f
            i64.const 10000000000
            i64.div_u
            local.get $e
            i64.extend_i32_u
            i64.shl
            local.set $a
            local.get $f
            i64.const 10000000000
            i64.rem_u
            local.get $e
            i64.extend_i32_u
            i64.shl
            local.set $c
            local.get $q
            local.get $a
            local.get $c
            i64.const 10000000000
            i64.div_u
            i64.add
            i32.const 1
            call $__fmt_u64
            local.set $q
            local.get $q
            local.get $c
            i64.const 10000000000
            i64.rem_u
            i32.const 10
            call $__fmt_u64
            local.set $q
          )
        )
        local.get $q
        i32.const 46
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
        local.get $q
        i32.const 48
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
        local.get $q
        local.get $w
        i32.const 832
        i32.add
        i32.sub
        return
      )
    )
    local.get $x
    f64.const 0
    f64.eq
    (if
      (then
        local.get $q
        i32.const 48
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
        i32.const 1
        return
      )
    )
    local.get $x
    f64.const 0
    f64.lt
    (if
      (then
        local.get $q
        i32.const 45
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
        local.get $x
        f64.neg
        local.set $x
      )
    )
    local.get $x
    f64.const inf
    f64.eq
    (if
      (then
        local.get $q
        i32.const 73
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
        local.get $q
        i32.const 110
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
        local.get $q
        i32.const 102
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
        local.get $q
        i32.const 105
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
        local.get $q
        i32.const 110
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
        local.get $q
        i32.const 105
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
        local.get $q
        i32.const 116
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
        local.get $q
        i32.const 121
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
      )
      (else
        local.get $x
        call $__dtoa
        local.set $len
        local.get $w
        i32.load offset=800
        local.set $pt
        local.get $w
        i32.const 804
        i32.add
        local.set $dig
        local.get $len
        local.get $pt
        i32.le_s
        local.get $pt
        i32.const 21
        i32.le_s
        i32.and
        (if
          (then
            local.get $q
            local.get $dig
            local.get $len
            memory.copy
            local.get $q
            local.get $len
            i32.add
            local.set $q
            local.get $len
            local.set $i
            (block $brk
              (loop $cont
                local.get $i
                local.get $pt
                i32.ge_s
                br_if $brk
                local.get $q
                i32.const 48
                i32.store8
                local.get $q
                i32.const 1
                i32.add
                local.set $q
                local.get $i
                i32.const 1
                i32.add
                local.set $i
                br $cont
              )
            )
          )
          (else
            local.get $pt
            i32.const 0
            i32.gt_s
            local.get $pt
            i32.const 21
            i32.le_s
            i32.and
            (if
              (then
                local.get $q
                local.get $dig
                local.get $pt
                memory.copy
                local.get $q
                local.get $pt
                i32.add
                local.set $q
                local.get $q
                i32.const 46
                i32.store8
                local.get $q
                i32.const 1
                i32.add
                local.set $q
                local.get $q
                local.get $dig
                local.get $pt
                i32.add
                local.get $len
                local.get $pt
                i32.sub
                memory.copy
                local.get $q
                local.get $len
                local.get $pt
                i32.sub
                i32.add
                local.set $q
              )
              (else
                local.get $pt
                i32.const -6
                i32.gt_s
                local.get $pt
                i32.const 0
                i32.le_s
                i32.and
                (if
                  (then
                    local.get $q
                    i32.const 48
                    i32.store8
                    local.get $q
                    i32.const 1
                    i32.add
                    local.set $q
                    local.get $q
                    i32.const 46
                    i32.store8
                    local.get $q
                    i32.const 1
                    i32.add
                    local.set $q
                    local.get $pt
                    local.set $i
                    (block $brk
                      (loop $cont
                        local.get $i
                        i32.const 0
                        i32.ge_s
                        br_if $brk
                        local.get $q
                        i32.const 48
                        i32.store8
                        local.get $q
                        i32.const 1
                        i32.add
                        local.set $q
                        local.get $i
                        i32.const 1
                        i32.add
                        local.set $i
                        br $cont
                      )
                    )
                    local.get $q
                    local.get $dig
                    local.get $len
                    memory.copy
                    local.get $q
                    local.get $len
                    i32.add
                    local.set $q
                  )
                  (else
                    local.get $q
                    local.get $dig
                    i32.const 1
                    memory.copy
                    local.get $q
                    i32.const 1
                    i32.add
                    local.set $q
                    local.get $len
                    i32.const 1
                    i32.gt_s
                    (if
                      (then
                        local.get $q
                        i32.const 46
                        i32.store8
                        local.get $q
                        i32.const 1
                        i32.add
                        local.set $q
                        local.get $q
                        local.get $dig
                        i32.const 1
                        i32.add
                        local.get $len
                        i32.const 1
                        i32.sub
                        memory.copy
                        local.get $q
                        local.get $len
                        i32.const 1
                        i32.sub
                        i32.add
                        local.set $q
                      )
                    )
                    local.get $q
                    i32.const 101
                    i32.store8
                    local.get $q
                    i32.const 1
                    i32.add
                    local.set $q
                    local.get $pt
                    i32.const 1
                    i32.sub
                    local.set $i
                    local.get $i
                    i32.const 0
                    i32.lt_s
                    (if
                      (then
                        local.get $q
                        i32.const 45
                        i32.store8
                        local.get $q
                        i32.const 1
                        i32.add
                        local.set $q
                        i32.const 0
                        local.get $i
                        i32.sub
                        local.set $i
                      )
                      (else
                        local.get $q
                        i32.const 43
                        i32.store8
                        local.get $q
                        i32.const 1
                        i32.add
                        local.set $q
                      )
                    )
                    local.get $q
                    local.get $i
                    i64.extend_i32_u
                    i32.const 1
                    call $__fmt_u64
                    local.set $q
                  )
                )
              )
            )
          )
        )
      )
    )
    local.get $q
    local.get $w
    i32.const 832
    i32.add
    i32.sub
  )
  (func $__i64_fmt (param $v i64) (result i32)
    (local $w i32) (local $q i32)
    call $__dtoa_ws
    local.tee $w
    i32.const 832
    i32.add
    local.set $q
    local.get $v
    i64.const 0
    i64.lt_s
    (if
      (then
        local.get $q
        i32.const 45
        i32.store8
        local.get $q
        i32.const 1
        i32.add
        local.set $q
        i64.const 0
        local.get $v
        i64.sub
        local.set $v
      )
    )
    local.get $q
    local.get $v
    i32.const 1
    call $__fmt_u64
    local.get $w
    i32.const 832
    i32.add
    i32.sub
  )
  (func $__print_i64_raw (param $v i64)
    (local $n i32)
    local.get $v
    call $__i64_fmt
    local.set $n
    call $__dtoa_ws
    i32.const 832
    i32.add
    local.get $n
    call $__write_bytes
  )
  (func $__print_i64 (param $v i64)
    local.get $v
    call $__print_i64_raw
    call $__print_nl
  )
)
```

----- RUN LOG -----
```logs
#(true, 1)
#(#(1, 2), "x")
[#(1, 2), #(17, 1)]
#(7, "s")
#(3, "z")
```
