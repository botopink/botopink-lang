----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val words = ["plain", "say \"hi\"", "back\\slash", "two\nlines"];
    @print(words);
    @print("top", words);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\05\00\00\00plain")
  (data (i32.const 268) "\08\00\00\00say \"hi\"")
  (data (i32.const 280) "\0a\00\00\00back\\slash")
  (data (i32.const 296) "\09\00\00\00two\nlines")
  (data (i32.const 312) "\02\00\00\00[s")
  (data (i32.const 320) "\03\00\00\00top")
  (global $__heap_ptr (mut i32) (i32.const 2304))
  (func $main
    (local $__mem0 i32)
    (local $words i32)
    i32.const 20
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 4
    i32.store
    local.get $__mem0
    i32.const 256
    i32.store offset=4
    local.get $__mem0
    i32.const 268
    i32.store offset=8
    local.get $__mem0
    i32.const 280
    i32.store offset=12
    local.get $__mem0
    i32.const 296
    i32.store offset=16
    local.get $__mem0
    local.set $words
    local.get $words
    i32.const 316
    i32.const 1
    call $__print_shaped_raw
    drop
    call $__print_nl
    i32.const 320
    call $__print_str_raw
    call $__print_sp
    local.get $words
    i32.const 316
    i32.const 1
    call $__print_shaped_raw
    drop
    call $__print_nl
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
    (local $s i32)
    local.get $x
    call $__f64_to_str
    local.set $s
    local.get $s
    i32.const 4
    i32.add
    local.get $s
    i32.load
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
  (func $__f64_to_str (param $x f64) (result i32)
    local.get $x
    call $__std_number_floatToString
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
    i32.const 117
    i32.eq
    (if
      (then
        local.get $go
        (if
          (then
            local.get $v
            i64.load
            call $__print_u64_raw
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
    i32.const 63
    i32.eq
    local.get $c
    i32.const 33
    i32.eq
    i32.or
    (if
      (then
        local.get $sh
        i32.const 1
        i32.add
        local.set $e
        local.get $go
        local.get $v
        i32.eqz
        i32.and
        (if
          (then
            i32.const 176
            i32.const 1819047278
            i32.store
            i32.const 176
            i32.const 4
            call $__write_bytes
            i32.const 0
            local.get $e
            i32.const 0
            call $__print_shaped_raw
            return
          )
        )
        local.get $go
        local.get $c
        i32.const 33
        i32.eq
        i32.and
        (if
          (then
            local.get $v
            i32.load
            local.set $v
          )
        )
        local.get $v
        local.get $e
        local.get $go
        call $__print_shaped_raw
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
  (global $__int_ws (mut i32) (i32.const 0))
  (func $__int_ws (result i32)
    global.get $__int_ws
    i32.eqz
    (if
      (then
        i32.const 48
        call $__alloc
        global.set $__int_ws
      )
    )
    global.get $__int_ws
  )
  (func $__fmt_u64 (param $q i32) (param $v i64) (param $width i32) (result i32)
    (local $t i32) (local $cnt i32)
    call $__int_ws
    i32.const 48
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
  (func $__i64_fmt (param $v i64) (result i32)
    (local $w i32) (local $q i32)
    call $__int_ws
    local.tee $w
    i32.const 0
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
    i32.const 0
    i32.add
    i32.sub
  )
  (func $__print_i64_raw (param $v i64)
    (local $n i32)
    local.get $v
    call $__i64_fmt
    local.set $n
    call $__int_ws
    i32.const 0
    i32.add
    local.get $n
    call $__write_bytes
  )
  (func $__print_i64 (param $v i64)
    local.get $v
    call $__print_i64_raw
    call $__print_nl
  )
  (func $__u64_fmt (param $v i64) (result i32)
    (local $w i32)
    call $__int_ws
    local.tee $w
    i32.const 0
    i32.add
    local.get $v
    i32.const 1
    call $__fmt_u64
    local.get $w
    i32.const 0
    i32.add
    i32.sub
  )
  (func $__print_u64_raw (param $v i64)
    (local $n i32)
    local.get $v
    call $__u64_fmt
    local.set $n
    call $__int_ws
    i32.const 0
    i32.add
    local.get $n
    call $__write_bytes
  )
  (func $__print_u64 (param $v i64)
    local.get $v
    call $__print_u64_raw
    call $__print_nl
  )
  ;; std-wasm (decision 440): its functions, transpiled from std_wasm.wasm
  (global $__std_sp (mut i32) (i32.const 2304))
  (data (i32.const 328) "-Infinity\00nan\00inf\000123456789abcdef\00NaN\00-0.0\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\02\00\00\00\03\00\00\00\04\00\t\00\00\00\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\13\03\03\03\03\03\03\03\03\03\03\03\03#\03\034\04\04\04D\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\01\00\00\00\00\00\00\00\05\00\00\00\00\00\00\00\19\00\00\00\00\00\00\00}\00\00\00\00\00\00\00q\02\00\00\00\00\00\005\0c\00\00\00\00\00\00\t=\00\00\00\00\00\00-1\01\00\00\00\00\00\e1\f5\05\00\00\00\00\00e\cd\1d\00\00\00\00\00\f9\02\95\00\00\00\00\00\dd\0e\e9\02\00\00\00\00QJ\8d\0e\00\00\00\00\95s\c2H\00\00\00\00\e9A\cck\01\00\00\00\8dI\fd\1a\07\00\00\00\c1o\f2\86#\00\00\00\c5.\bc\a2\b1\00\00\00\d9\e9\ac-x\03\00\00=\91`\e4X\11\00\001\d6\e2u\bcV\00\00\f5.nM\ae\b1\01\00\c9\ea&\83gx\08\00\ed\95\c2\8f\05Z*\00\a1\ed\cc\ce\1b\c2\d3\00%\a4\00\n\8b\ca\"\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00@\95YiYUUTU\15UUV\04\05\15A\10TU@EQUD@EPDPUUE\00@\00@@\04D\96eUVUE@ETQA\15@U\91UUUU@Q\05\01\00\00TETTEU\05\04\00\10\04\10\14\04@\00\00\00\01@UU\15AT\04\00\00D\00\01\00\00\00\00@A\00\00DPDEPT\00UUTUeQ\00@\00@\01\00\00\01\00\05\01\00\11TQQTUU\05\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00 4Pe\c0_\c9\a6R\bb\13\cb\ae\c4@\c2\18\06\c8\dfq\00\d5\a8|\f5o\0f\daX\fc'\13nGV5}$ e\02\c7\e7h\e4\8c\a4\1d\e9\e6\02h\d7\cd9ayw\fc\c2@[\ef\16y\8c\deC\ff\a7Q\f9\91\f3\b2x\f5\bd\be\11\e8W\e9\d6\e8\be\e8{\b0T\ac\8f\84\8du\1b\ea#\a4\99\e9\f9\d3\8b\b7\a3q@a\da>\15\ce\e3>\cbs\f9H\08\8c\97\b4'\d5\1bp\10\a2\bf\ef\b9\eb\852\15M\b4M\b4\9b\bbo\19\96\b6\07l\f8\e7\ee\ad6\d9\b4\f5\915\ae\13\"\"\18\afNjhM\91\da\aa=O@t\1e\9f\bd\9e\e0\06\a1\c0\98W\c2\a7\fd\a4\0e\90\17\0e}Iqs\e3 \8f\b2 \d8v\05\14;\12\85=t4\81\13C\b0\ad)z_'\f45\1c\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\10\00\00\00\00\00\00\00\00\b94\032\b7\f4\ad\14\10\db\1a\b3\08\92T\0e\r0}\95\14G\ba\1af\08\8fM&\ad\c6m\f5\98\bf\85\e2\b7E\11\ca\96\85=\92\bd\1d\eb\fc\a1\18`\dc\efR\16<\92\ae\"\0b\b8\c1\b4\83\9d-[\05b\da\1c0L~\8fN\8b\b2[\16\f4R\9f\8bV\a5\12\fb\d4\82vC\ed\8a\f0\8f\e7\f91\15e\19\18P\f1\9b\d9J\13\ee\b4(L\f0\a6\86\c1%\1f\03_\c2p\cb\9eI\16\e6B\88\9cD\eb \14\b0e\086\adn\a5\85\85\f0\ca\14\e2\fd\03\1a\0b\89\99y\d5\b1=\t\d8\da\97:5\eb\cf\10\ac6?^s\bb8\cf>gR\faD\af\ba\15")
  (func $__std_f2 (param $p0 i32) (param $p1 i32) (result i32)
    (local $l0 i32)
    local.get $p1
    i32.const 4
    i32.add
    call $__alloc
    local.tee $l0
    local.get $p1
    i32.store
    (block $b0
      local.get $p1
      i32.eqz
      br_if $b0
      local.get $l0
      i32.const 4
      i32.add
      local.get $p0
      local.get $p1
      memory.copy
    )
    local.get $l0
  )
  (func $__std_number_floatToString (param $p0 f64) (result i32)
    (local $l0 i32) (local $l1 i32) (local $l2 i32) (local $l3 i64) (local $l4 i64) (local $l5 i32)
    (local $l6 i64) (local $l7 i32) (local $l8 i64) (local $l9 i64) (local $l10 i32) (local $l11 i32)
    (local $l12 i32) (local $l13 i32) (local $l14 i32) (local $l15 i32) (local $l16 i32) (local $l17 i64)
    (local $l18 i64) (local $l19 i64) (local $l20 i32)
    global.get $__std_sp
    i32.const 784
    i32.sub
    local.tee $l0
    global.set $__std_sp
    i32.const 328
    local.set $l1
    (block $b0
      (block $b1
        local.get $p0
        local.get $p0
        f64.eq
        br_if $b1
        local.get $l1
        i32.const 35
        i32.add
        local.set $l2
        i32.const 3
        local.set $l1
        br $b0
      )
      (block $b2
        local.get $p0
        f64.abs
        f64.const inf
        f64.ne
        br_if $b2
        i32.const 328
        local.tee $l1
        i32.const 0
        i32.add
        local.get $l1
        i32.const 1
        i32.add
        local.get $p0
        f64.const 0e0
        f64.lt
        local.tee $l1
        select
        local.set $l2
        i32.const 9
        i32.const 8
        local.get $l1
        select
        local.set $l1
        br $b0
      )
      (block $b3
        local.get $p0
        f64.const 0e0
        f64.ne
        br_if $b3
        i32.const 328
        local.tee $l1
        i32.const 39
        i32.add
        local.get $l1
        i32.const 40
        i32.add
        local.get $p0
        i64.reinterpret_f64
        i64.const 0
        i64.lt_s
        local.tee $l1
        select
        local.set $l2
        i32.const 4
        i32.const 3
        local.get $l1
        select
        local.set $l1
        br $b0
      )
      local.get $l0
      i32.const 211
      i32.add
      i32.const 1
      i32.add
      local.set $l2
      local.get $p0
      i64.reinterpret_f64
      local.tee $l3
      i64.const 52
      i64.shr_u
      i32.wrap_i64
      i32.const 2047
      i32.and
      local.set $l1
      i64.const 0
      local.set $l4
      i32.const 328
      i32.const 48
      i32.add
      i32.load8_u offset=8
      local.set $l5
      (block $b4
        (block $b5
          local.get $l3
          i64.const 4503599627370495
          i64.and
          local.tee $l6
          i64.const 0
          i64.ne
          br_if $b5
          local.get $l1
          br_if $b5
          i32.const 0
          local.set $l1
          br $b4
        )
        (block $b6
          local.get $l1
          i32.const 2047
          i32.ne
          br_if $b6
          i32.const 2147483647
          local.set $l1
          local.get $l6
          local.set $l4
          br $b4
        )
        local.get $l6
        i64.const 0
        i64.ne
        local.get $l1
        i32.eqz
        i32.or
        local.set $l7
        local.get $l6
        i64.const 4503599627370496
        i64.or
        local.get $l6
        local.get $l1
        select
        local.tee $l4
        i64.const 2
        i64.shl
        local.set $l8
        local.get $l4
        i64.const 1
        i64.and
        local.set $l9
        (block $b7
          (block $b8
            (block $b9
              local.get $l1
              i32.const -1077
              i32.add
              i32.const -1076
              local.get $l1
              select
              local.tee $l1
              i32.const -1
              i32.gt_s
              br_if $b9
              i32.const 0
              local.get $l1
              i32.sub
              local.tee $l10
              i64.extend_i32_u
              i64.const 196742565691928
              i64.mul
              i64.const 48
              i64.shr_u
              i32.wrap_i64
              local.get $l1
              i32.const -1
              i32.ne
              i32.sub
              local.tee $l11
              local.get $l10
              local.get $l11
              i32.sub
              local.tee $l10
              i64.extend_i32_u
              i64.const 163391164108059
              i64.mul
              i64.const 46
              i64.shr_u
              i32.wrap_i64
              local.tee $l12
              i32.sub
              i32.const 124
              i32.add
              local.set $l13
              i32.const 328
              i32.const 944
              i32.add
              local.get $l10
              i32.const 65535
              i32.and
              i32.const 26
              i32.div_u
              local.tee $l14
              i32.const 4
              i32.shl
              i32.add
              local.set $l15
              (block $b10
                (block $b11
                  local.get $l10
                  local.get $l14
                  i32.const 26
                  i32.mul
                  local.tee $l14
                  i32.ne
                  br_if $b11
                  local.get $l15
                  i64.load offset=8
                  local.set $l4
                  local.get $l15
                  i64.load
                  local.set $l6
                  br $b10
                )
                i32.const 328
                local.set $l16
                local.get $l0
                i32.const 112
                i32.add
                local.get $l15
                i64.load
                i64.const 0
                local.get $l16
                i32.const 336
                i32.add
                local.get $l10
                local.get $l14
                i32.sub
                i32.const 3
                i32.shl
                i32.add
                i64.load
                local.tee $l4
                i64.const 0
                call $__std_f14
                local.get $l0
                i32.const 128
                i32.add
                local.get $l15
                i64.load offset=8
                i64.const 0
                local.get $l4
                i64.const 0
                call $__std_f14
                local.get $l0
                i32.const 80
                i32.add
                local.get $l0
                i64.load offset=112
                local.get $l0
                i64.load offset=120
                local.get $l12
                local.get $l14
                i64.extend_i32_u
                i64.const 163391164108059
                i64.mul
                i64.const 46
                i64.shr_u
                i32.wrap_i64
                i32.sub
                local.tee $l15
                call $__std_f15
                local.get $l0
                i32.const 96
                i32.add
                local.get $l0
                i64.load offset=128
                local.get $l0
                i64.load offset=136
                i32.const 64
                local.get $l15
                i32.sub
                i32.const 127
                i32.and
                call $__std_f16
                local.get $l0
                i64.load offset=88
                local.get $l0
                i64.load offset=104
                i64.add
                local.get $l0
                i64.load offset=80
                local.tee $l6
                local.get $l0
                i64.load offset=96
                i64.add
                local.tee $l4
                local.get $l6
                i64.lt_u
                i64.extend_i32_u
                i64.add
                local.get $l4
                local.get $l16
                i32.const 544
                i32.add
                local.get $l10
                i32.const 2
                i32.shr_u
                i32.const 1073741820
                i32.and
                i32.add
                i32.load
                local.get $l10
                i32.const 1
                i32.shl
                i32.shr_u
                i32.const 3
                i32.and
                i64.extend_i32_u
                i64.add
                local.tee $l6
                local.get $l4
                i64.lt_u
                i64.extend_i32_u
                i64.add
                local.get $l6
                i64.const 1
                i64.add
                local.tee $l6
                i64.eqz
                i64.extend_i32_u
                i64.add
                local.set $l4
              )
              local.get $l11
              local.get $l1
              i32.add
              local.set $l15
              local.get $l0
              local.get $l4
              i64.store offset=272
              local.get $l0
              local.get $l6
              i64.store offset=264
              local.get $l8
              local.get $l0
              i32.const 264
              i32.add
              local.get $l13
              call $__std_f4
              local.set $l4
              local.get $l8
              i64.const 2
              i64.or
              local.get $l0
              i32.const 264
              i32.add
              local.get $l13
              call $__std_f4
              local.set $l17
              local.get $l7
              i64.extend_i32_u
              i64.const -1
              i64.xor
              local.get $l8
              i64.add
              local.get $l0
              i32.const 264
              i32.add
              local.get $l13
              call $__std_f4
              local.set $l6
              (block $b12
                local.get $l11
                i32.const 2
                i32.ge_u
                br_if $b12
                local.get $l17
                local.get $l9
                i64.sub
                local.set $l17
                local.get $l7
                local.get $l9
                i64.eqz
                i32.and
                local.set $l10
                i32.const 1
                local.set $l7
                br $b7
              )
              i32.const 0
              local.set $l10
              local.get $l11
              i32.const 62
              i32.gt_u
              br_if $b8
              local.get $l8
              i64.const -1
              local.get $l11
              i64.extend_i32_u
              i64.shl
              i64.const -1
              i64.xor
              i64.and
              i64.eqz
              local.set $l7
              br $b7
            )
            local.get $l1
            i64.extend_i32_u
            i64.const 169464822037455
            i64.mul
            i64.const 49
            i64.shr_u
            i32.wrap_i64
            local.get $l1
            i32.const 3
            i32.gt_u
            i32.sub
            local.tee $l15
            local.get $l1
            i32.sub
            local.get $l15
            i64.extend_i32_u
            i64.const 163391164108059
            i64.mul
            i64.const 46
            i64.shr_u
            i32.wrap_i64
            local.tee $l13
            i32.add
            i32.const 125
            i32.add
            local.set $l1
            i32.const 328
            i32.const 704
            i32.add
            local.get $l15
            i32.const 25
            i32.add
            i32.const 65535
            i32.and
            i32.const 26
            i32.div_u
            local.tee $l10
            i32.const 4
            i32.shl
            i32.add
            local.set $l11
            (block $b13
              (block $b14
                local.get $l10
                i32.const 26
                i32.mul
                local.tee $l10
                local.get $l15
                i32.ne
                br_if $b14
                local.get $l11
                i64.load offset=8
                local.set $l4
                local.get $l11
                i64.load
                local.set $l6
                br $b13
              )
              i32.const 328
              local.set $l14
              local.get $l0
              i32.const 64
              i32.add
              local.get $l11
              i64.load
              i64.const -1
              i64.add
              i64.const 0
              local.get $l14
              i32.const 336
              i32.add
              local.get $l10
              local.get $l15
              i32.sub
              i32.const 3
              i32.shl
              i32.add
              i64.load
              local.tee $l4
              i64.const 0
              call $__std_f14
              local.get $l0
              i32.const 48
              i32.add
              local.get $l11
              i64.load offset=8
              i64.const 0
              local.get $l4
              i64.const 0
              call $__std_f14
              local.get $l0
              i32.const 16
              i32.add
              local.get $l0
              i64.load offset=64
              local.get $l0
              i64.load offset=72
              local.get $l10
              i64.extend_i32_u
              i64.const 163391164108059
              i64.mul
              i64.const 46
              i64.shr_u
              i32.wrap_i64
              local.get $l13
              i32.sub
              local.tee $l11
              call $__std_f15
              local.get $l0
              i32.const 32
              i32.add
              local.get $l0
              i64.load offset=48
              local.get $l0
              i64.load offset=56
              i32.const 64
              local.get $l11
              i32.sub
              i32.const 127
              i32.and
              call $__std_f16
              local.get $l0
              i64.load offset=40
              local.get $l0
              i64.load offset=24
              i64.add
              local.get $l0
              i64.load offset=32
              local.tee $l6
              local.get $l0
              i64.load offset=16
              i64.add
              local.tee $l4
              local.get $l6
              i64.lt_u
              i64.extend_i32_u
              i64.add
              local.get $l4
              local.get $l14
              i32.const 628
              i32.add
              local.get $l15
              i32.const 2
              i32.shr_u
              i32.const 1073741820
              i32.and
              i32.add
              i32.load
              local.get $l15
              i32.const 1
              i32.shl
              i32.shr_u
              i32.const 3
              i32.and
              i64.extend_i32_u
              i64.add
              local.tee $l6
              local.get $l4
              i64.lt_u
              i64.extend_i32_u
              i64.add
              local.get $l6
              i64.const 1
              i64.add
              local.tee $l6
              i64.eqz
              i64.extend_i32_u
              i64.add
              local.set $l4
            )
            local.get $l0
            local.get $l4
            i64.store offset=272
            local.get $l0
            local.get $l6
            i64.store offset=264
            i32.const 0
            local.set $l10
            local.get $l8
            local.get $l0
            i32.const 264
            i32.add
            local.get $l1
            call $__std_f4
            local.set $l4
            local.get $l8
            i64.const 2
            i64.or
            local.tee $l18
            local.get $l0
            i32.const 264
            i32.add
            local.get $l1
            call $__std_f4
            local.set $l17
            local.get $l7
            i64.extend_i32_u
            i64.const -1
            i64.xor
            local.get $l8
            i64.add
            local.tee $l19
            local.get $l0
            i32.const 264
            i32.add
            local.get $l1
            call $__std_f4
            local.set $l6
            local.get $l15
            i32.const 22
            i32.ge_u
            br_if $b8
            (block $b15
              local.get $l8
              i64.const 5
              i64.rem_u
              i64.const 0
              i64.ne
              br_if $b15
              local.get $l8
              local.get $l15
              call $__std_f5
              local.set $l7
              br $b7
            )
            (block $b16
              local.get $l9
              i32.wrap_i64
              br_if $b16
              local.get $l19
              local.get $l15
              call $__std_f5
              local.set $l10
              br $b8
            )
            local.get $l17
            local.get $l18
            local.get $l15
            call $__std_f5
            i64.extend_i32_u
            i64.const 1
            i64.and
            i64.sub
            local.set $l17
          )
          i32.const 0
          local.set $l7
        )
        i32.const 0
        local.set $l1
        i32.const 0
        local.set $l11
        (block $b17
          (loop $b18
            local.get $l17
            i64.const 10
            i64.div_u
            local.tee $l17
            local.get $l6
            i64.const 10
            i64.div_u
            local.tee $l8
            i64.le_u
            br_if $b17
            local.get $l11
            i32.const 1
            i32.add
            local.set $l11
            local.get $l7
            local.get $l1
            i32.const 255
            i32.and
            i32.eqz
            i32.and
            local.set $l7
            local.get $l10
            local.get $l6
            local.get $l8
            i64.const 10
            i64.mul
            i64.sub
            i64.eqz
            i32.and
            local.set $l10
            local.get $l4
            local.get $l4
            i64.const 10
            i64.div_u
            local.tee $l18
            i64.const 10
            i64.mul
            i64.sub
            i32.wrap_i64
            local.set $l1
            local.get $l8
            local.set $l6
            local.get $l18
            local.set $l4
            br $b18
          )
        )
        (block $b19
          local.get $l10
          i32.const 1
          i32.and
          i32.eqz
          br_if $b19
          (loop $b20
            local.get $l6
            local.get $l6
            i64.const 10
            i64.div_u
            local.tee $l8
            i64.const 10
            i64.mul
            i64.sub
            i64.const 0
            i64.ne
            br_if $b19
            local.get $l11
            i32.const 1
            i32.add
            local.set $l11
            local.get $l7
            local.get $l1
            i32.const 255
            i32.and
            i32.eqz
            i32.and
            local.set $l7
            local.get $l4
            local.get $l4
            i64.const 10
            i64.div_u
            local.tee $l17
            i64.const 10
            i64.mul
            i64.sub
            i32.wrap_i64
            local.set $l1
            local.get $l8
            local.set $l6
            local.get $l17
            local.set $l4
            br $b20
          )
        )
        local.get $l4
        local.get $l4
        local.get $l6
        i64.eq
        local.get $l9
        i64.eqz
        local.get $l10
        i32.and
        i32.const 1
        i32.xor
        i32.and
        i32.const 4
        i32.const 5
        local.get $l4
        i64.const 1
        i64.and
        i64.eqz
        select
        local.get $l1
        local.get $l1
        i32.const 255
        i32.and
        i32.const 5
        i32.eq
        select
        local.get $l1
        local.get $l7
        i32.const 1
        i32.and
        select
        i32.const 255
        i32.and
        i32.const 4
        i32.gt_u
        i32.or
        i64.extend_i32_u
        i64.add
        local.set $l4
        local.get $l11
        local.get $l15
        i32.add
        local.set $l1
      )
      local.get $l0
      local.get $l3
      i64.const 0
      i64.lt_s
      i32.store8 offset=764
      (block $b21
        (block $b22
          (block $b23
            local.get $l5
            i32.const 1
            i32.and
            br_if $b23
            local.get $l0
            i32.load8_u offset=764
            local.set $l7
            (block $b24
              local.get $l1
              i32.const 2147483647
              i32.ne
              br_if $b24
              local.get $l0
              local.get $l7
              i32.store8 offset=276
              local.get $l0
              i32.const 2147483647
              i32.store offset=272
              local.get $l0
              local.get $l4
              i64.store offset=264
              local.get $l0
              i32.const 8
              i32.add
              local.get $l0
              i32.const 211
              i32.add
              local.get $l0
              i32.const 264
              i32.add
              call $__std_f6
              local.get $l0
              i32.load offset=12
              local.set $l15
              local.get $l0
              i32.load offset=8
              local.set $l1
              br $b21
            )
            local.get $l0
            local.get $l4
            i64.store offset=768
            local.get $l4
            call $__std_f7
            local.set $l11
            (block $b25
              (block $b26
                local.get $l7
                i32.const 1
                i32.and
                br_if $b26
                i32.const 0
                local.set $l7
                local.get $l0
                i32.const 211
                i32.add
                local.set $l2
                br $b25
              )
              local.get $l0
              i32.const 45
              i32.store8 offset=211
              i32.const 1
              local.set $l7
            )
            local.get $l0
            i32.const 211
            i32.add
            local.get $l7
            i32.const 2
            i32.or
            local.tee $l10
            i32.add
            local.get $l0
            i32.const 768
            i32.add
            local.get $l11
            i32.const -1
            i32.add
            local.tee $l5
            call $__std_f8
            local.get $l0
            i32.const 211
            i32.add
            local.get $l7
            i32.add
            local.get $l0
            i64.load offset=768
            i64.const 10
            i64.rem_u
            i32.wrap_i64
            i32.const 48
            i32.or
            i32.store8
            local.get $l2
            i32.const 46
            i32.store8 offset=1
            local.get $l0
            i32.const 211
            i32.add
            local.get $l10
            local.get $l5
            i32.add
            local.get $l7
            i32.const 1
            i32.add
            local.get $l11
            i32.const 1
            i32.gt_u
            select
            local.tee $l10
            i32.add
            i32.const 101
            i32.store8
            local.get $l10
            i32.const 1
            i32.add
            local.set $l5
            (block $b27
              local.get $l11
              local.get $l1
              i32.add
              local.tee $l1
              i32.const 1
              i32.lt_s
              br_if $b27
              local.get $l1
              i32.const -1
              i32.add
              local.set $l7
              br $b22
            )
            local.get $l0
            i32.const 211
            i32.add
            local.get $l5
            i32.add
            i32.const 45
            i32.store8
            i32.const 1
            local.get $l1
            i32.sub
            local.set $l7
            local.get $l10
            i32.const 2
            i32.add
            local.set $l5
            br $b22
          )
          local.get $l0
          i32.load8_u offset=764
          local.set $l7
          (block $b28
            local.get $l1
            i32.const 2147483647
            i32.ne
            br_if $b28
            local.get $l0
            local.get $l7
            i32.store8 offset=276
            local.get $l0
            i32.const 2147483647
            i32.store offset=272
            local.get $l0
            local.get $l4
            i64.store offset=264
            local.get $l0
            local.get $l0
            i32.const 211
            i32.add
            local.get $l0
            i32.const 264
            i32.add
            call $__std_f6
            local.get $l0
            i32.load offset=4
            local.set $l15
            local.get $l0
            i32.load
            local.set $l1
            br $b21
          )
          local.get $l0
          local.get $l4
          i64.store offset=264
          (block $b29
            local.get $l4
            call $__std_f7
            local.tee $l11
            local.get $l1
            local.get $l1
            i32.const 31
            i32.shr_s
            local.tee $l10
            i32.xor
            local.get $l10
            i32.sub
            i32.add
            i32.const 51
            i32.le_u
            br_if $b29
            br $b21
          )
          (block $b30
            (block $b31
              local.get $l7
              i32.const 1
              i32.and
              br_if $b31
              i32.const 0
              local.set $l10
              local.get $l0
              i32.const 211
              i32.add
              local.set $l2
              br $b30
            )
            local.get $l0
            i32.const 45
            i32.store8 offset=211
            i32.const 1
            local.set $l10
          )
          (block $b32
            local.get $l11
            local.get $l1
            i32.add
            local.tee $l7
            i32.const 1
            i32.ge_s
            br_if $b32
            local.get $l0
            i32.const 211
            i32.add
            local.get $l10
            i32.add
            i32.const 48
            i32.store8
            local.get $l2
            i32.const 46
            i32.store8 offset=1
            local.get $l10
            i32.const 2
            i32.or
            local.set $l1
            (block $b33
              i32.const 0
              local.get $l7
              i32.sub
              local.tee $l10
              i32.eqz
              br_if $b33
              local.get $l0
              i32.const 211
              i32.add
              local.get $l1
              i32.add
              i32.const 48
              local.get $l10
              memory.fill
            )
            local.get $l0
            i32.const 211
            i32.add
            local.get $l1
            local.get $l7
            i32.sub
            local.tee $l1
            i32.add
            local.get $l0
            i32.const 264
            i32.add
            local.get $l11
            call $__std_f8
            local.get $l1
            local.get $l11
            i32.add
            local.set $l15
            local.get $l0
            i32.const 211
            i32.add
            local.set $l1
            br $b21
          )
          (block $b34
            local.get $l7
            local.get $l11
            i32.lt_u
            br_if $b34
            local.get $l2
            local.get $l0
            i32.const 264
            i32.add
            local.get $l11
            call $__std_f8
            (block $b35
              local.get $l1
              i32.eqz
              br_if $b35
              local.get $l2
              local.get $l11
              i32.add
              i32.const 48
              local.get $l1
              memory.fill
            )
            local.get $l10
            local.get $l7
            i32.add
            local.set $l15
            local.get $l0
            i32.const 211
            i32.add
            local.set $l1
            br $b21
          )
          local.get $l2
          local.get $l7
          i32.add
          local.tee $l5
          i32.const 1
          i32.add
          local.get $l0
          i32.const 264
          i32.add
          i32.const 0
          local.get $l1
          i32.sub
          call $__std_f8
          local.get $l5
          i32.const 46
          i32.store8
          local.get $l2
          local.get $l0
          i32.const 264
          i32.add
          local.get $l7
          call $__std_f8
          local.get $l11
          local.get $l10
          i32.add
          i32.const 1
          i32.add
          local.set $l15
          local.get $l0
          i32.const 211
          i32.add
          local.set $l1
          br $b21
        )
        i32.const 10
        local.set $l10
        (block $b36
          local.get $l7
          i32.const 999999999
          i32.gt_u
          br_if $b36
          (block $b37
            local.get $l7
            i32.const 99999999
            i32.le_u
            br_if $b37
            i32.const 9
            local.set $l10
            br $b36
          )
          (block $b38
            local.get $l7
            i32.const 9999999
            i32.le_u
            br_if $b38
            i32.const 8
            local.set $l10
            br $b36
          )
          (block $b39
            local.get $l7
            i32.const 999999
            i32.le_u
            br_if $b39
            i32.const 7
            local.set $l10
            br $b36
          )
          (block $b40
            local.get $l7
            i32.const 99999
            i32.le_u
            br_if $b40
            i32.const 6
            local.set $l10
            br $b36
          )
          (block $b41
            local.get $l7
            i32.const 9999
            i32.le_u
            br_if $b41
            i32.const 5
            local.set $l10
            br $b36
          )
          (block $b42
            local.get $l7
            i32.const 999
            i32.le_u
            br_if $b42
            i32.const 4
            local.set $l10
            br $b36
          )
          (block $b43
            local.get $l7
            i32.const 99
            i32.le_u
            br_if $b43
            i32.const 3
            local.set $l10
            br $b36
          )
          i32.const 2
          i32.const 1
          local.get $l7
          i32.const 9
          i32.gt_u
          select
          local.set $l10
        )
        local.get $l10
        local.get $l5
        i32.add
        local.tee $l15
        local.get $l0
        i32.const 211
        i32.add
        i32.add
        i32.const -1
        i32.add
        local.set $l1
        i32.const 0
        local.set $l11
        (loop $b44
          (block $b45
            local.get $l11
            i32.const 2
            i32.add
            local.tee $l5
            local.get $l10
            i32.lt_u
            br_if $b45
            (block $b46
              (loop $b47
                local.get $l11
                local.get $l10
                i32.ge_u
                br_if $b46
                local.get $l1
                local.get $l7
                local.get $l7
                i32.const 10
                i32.div_u
                local.tee $l5
                i32.const 10
                i32.mul
                i32.sub
                i32.const 48
                i32.or
                i32.store8
                local.get $l1
                i32.const -1
                i32.add
                local.set $l1
                local.get $l11
                i32.const 1
                i32.add
                local.set $l11
                local.get $l5
                local.set $l7
                br $b47
              )
            )
            local.get $l0
            i32.const 211
            i32.add
            local.set $l1
            br $b21
          )
          local.get $l1
          i32.const -1
          i32.add
          local.get $l7
          local.get $l7
          i32.const 100
          i32.div_u
          local.tee $l11
          i32.const 100
          i32.mul
          i32.sub
          local.tee $l7
          i32.const 255
          i32.and
          i32.const 10
          i32.div_u
          local.tee $l2
          i32.const 48
          i32.or
          i32.store8
          local.get $l1
          local.get $l7
          local.get $l2
          i32.const 10
          i32.mul
          i32.sub
          i32.const 48
          i32.or
          i32.store8
          local.get $l1
          i32.const -2
          i32.add
          local.set $l1
          local.get $l11
          local.set $l7
          local.get $l5
          local.set $l11
          br $b44
        )
      )
      local.get $l1
      local.get $l1
      i32.load8_u
      local.tee $l12
      i32.const 45
      i32.eq
      local.tee $l11
      i32.add
      local.set $l1
      i32.const 0
      local.set $l7
      (block $b48
        local.get $l15
        local.get $l11
        i32.sub
        local.tee $l10
        i32.eqz
        br_if $b48
        i32.const 0
        local.set $l11
        (loop $b49
          local.get $l10
          local.get $l11
          i32.eq
          br_if $b48
          (block $b50
            local.get $l1
            local.get $l11
            i32.add
            i32.load8_u
            i32.const 101
            i32.ne
            br_if $b50
            local.get $l11
            local.set $l7
            br $b48
          )
          local.get $l11
          i32.const 1
          i32.add
          local.set $l11
          br $b49
        )
      )
      i64.const 17179869184
      local.set $l4
      (block $b51
        local.get $l10
        local.get $l7
        i32.const 1
        i32.add
        local.tee $l11
        i32.eq
        br_if $b51
        local.get $l10
        local.get $l11
        i32.sub
        local.set $l5
        (block $b52
          (block $b53
            (block $b54
              (block $b55
                (block $b56
                  (block $b57
                    (block $b58
                      local.get $l1
                      local.get $l11
                      i32.add
                      local.tee $l2
                      i32.load8_u
                      i32.const -43
                      i32.add
                      br_table $b58 $b56 $b57 $b56
                    )
                    local.get $l0
                    i32.const 264
                    i32.add
                    local.get $l2
                    i32.const 1
                    i32.add
                    local.get $l5
                    i32.const -1
                    i32.add
                    call $__std_f9
                    br $b55
                  )
                  i64.const 0
                  local.set $l4
                  i64.const 17179869184
                  local.set $l6
                  local.get $l5
                  i32.const -1
                  i32.add
                  local.tee $l11
                  i32.eqz
                  br_if $b52
                  local.get $l2
                  i32.const 1
                  i32.add
                  local.tee $l5
                  i32.load8_u
                  i32.const 95
                  i32.eq
                  br_if $b52
                  local.get $l1
                  local.get $l10
                  i32.add
                  i32.const -1
                  i32.add
                  i32.load8_u
                  i32.const 95
                  i32.eq
                  br_if $b52
                  i32.const 0
                  local.set $l2
                  (loop $b59
                    (block $b60
                      local.get $l11
                      br_if $b60
                      i64.const 0
                      local.set $l6
                      br $b53
                    )
                    (block $b61
                      local.get $l5
                      i32.load8_u
                      local.tee $l10
                      i32.const 95
                      i32.eq
                      br_if $b61
                      (block $b62
                        local.get $l10
                        i32.const -48
                        i32.add
                        i32.const 255
                        i32.and
                        local.tee $l15
                        i32.const 9
                        i32.le_u
                        br_if $b62
                        i64.const 17179869184
                        local.set $l6
                        br $b53
                      )
                      (block $b63
                        (block $b64
                          local.get $l2
                          i32.eqz
                          br_if $b64
                          local.get $l0
                          local.get $l2
                          i64.extend_i32_s
                          i64.const 10
                          i64.mul
                          local.tee $l4
                          i64.const 32
                          i64.shr_u
                          i32.wrap_i64
                          local.tee $l2
                          local.get $l4
                          i32.wrap_i64
                          local.tee $l10
                          i32.const 31
                          i32.shr_s
                          local.tee $l13
                          i32.ne
                          i32.store8 offset=264
                          local.get $l2
                          local.get $l13
                          i32.eq
                          br_if $b63
                          br $b54
                        )
                        i32.const 48
                        local.get $l10
                        i32.sub
                        i32.const 24
                        i32.shl
                        i32.const 24
                        i32.shr_s
                        local.set $l2
                        br $b61
                      )
                      local.get $l0
                      local.get $l15
                      i32.const 0
                      i32.gt_s
                      local.get $l10
                      local.get $l15
                      i32.sub
                      local.tee $l2
                      local.get $l10
                      i32.lt_s
                      i32.xor
                      local.tee $l10
                      i32.store8 offset=264
                      local.get $l10
                      br_if $b54
                    )
                    local.get $l11
                    i32.const -1
                    i32.add
                    local.set $l11
                    local.get $l5
                    i32.const 1
                    i32.add
                    local.set $l5
                    br $b59
                  )
                )
                local.get $l0
                i32.const 264
                i32.add
                local.get $l2
                local.get $l5
                call $__std_f9
              )
              local.get $l0
              i64.load offset=264
              local.set $l4
              br $b51
            )
            i64.const 0
            local.set $l4
            i64.const 12884901888
            local.set $l6
            br $b52
          )
          local.get $l2
          i64.extend_i32_u
          local.set $l4
        )
        local.get $l4
        local.get $l6
        i64.or
        local.set $l4
      )
      local.get $l0
      i32.const 364
      i32.add
      i32.const 1
      i32.add
      local.set $l20
      local.get $l0
      i32.const 300
      i32.add
      i32.const 1
      i32.add
      local.set $l5
      local.get $l0
      i32.const 147
      i32.add
      local.set $l2
      i32.const 0
      local.set $l11
      (loop $b65
        (block $b66
          (block $b67
            (block $b68
              (block $b69
                local.get $l7
                br_if $b69
                local.get $l4
                i32.wrap_i64
                i32.const 0
                local.get $l4
                i64.const 281470681743360
                i64.and
                i64.eqz
                select
                local.set $l15
                local.get $l11
                i32.const 0
                i32.ne
                local.set $l13
                (block $b70
                  (loop $b71
                    local.get $l11
                    local.tee $l1
                    i32.const 2
                    i32.lt_u
                    br_if $b70
                    local.get $l1
                    i32.const -1
                    i32.add
                    local.tee $l11
                    local.get $l0
                    i32.const 264
                    i32.add
                    i32.add
                    i32.load8_u
                    i32.const 48
                    i32.eq
                    br_if $b71
                  )
                  local.get $l11
                  i32.const 1
                  i32.add
                  local.set $l13
                )
                local.get $l12
                i32.const 45
                i32.eq
                br_if $b68
                i32.const 0
                local.set $l7
                local.get $l0
                i32.const 300
                i32.add
                local.set $l5
                br $b67
              )
              local.get $l1
              i32.load8_u
              local.tee $l10
              i32.const 46
              i32.eq
              br_if $b66
              local.get $l0
              i32.const 264
              i32.add
              local.get $l11
              i32.add
              local.get $l10
              i32.store8
              local.get $l11
              i32.const 1
              i32.add
              local.set $l11
              br $b66
            )
            local.get $l0
            i32.const 45
            i32.store8 offset=300
            i32.const 1
            local.set $l7
          )
          local.get $l0
          i32.const 300
          i32.add
          local.get $l7
          i32.add
          local.get $l0
          i32.load8_u offset=264
          i32.store8
          local.get $l5
          i32.const 46
          i32.store8 offset=1
          local.get $l7
          i32.const 2
          i32.or
          local.set $l11
          (block $b72
            (block $b73
              local.get $l1
              i32.const 1
              i32.le_u
              br_if $b73
              (block $b74
                local.get $l13
                i32.const -1
                i32.add
                local.tee $l1
                i32.eqz
                br_if $b74
                local.get $l0
                i32.const 300
                i32.add
                local.get $l11
                i32.add
                local.get $l0
                i32.const 264
                i32.add
                i32.const 1
                i32.add
                local.get $l1
                memory.copy
              )
              local.get $l11
              local.get $l1
              i32.add
              local.set $l1
              br $b72
            )
            local.get $l0
            i32.const 300
            i32.add
            local.get $l11
            i32.add
            i32.const 48
            i32.store8
            local.get $l7
            i32.const 3
            i32.add
            local.set $l1
          )
          local.get $l0
          i32.const 300
          i32.add
          local.get $l1
          i32.add
          i32.const 101
          i32.store8
          local.get $l15
          local.get $l15
          i32.const 31
          i32.shr_s
          local.tee $l11
          i32.xor
          local.set $l10
          i32.const 0
          local.set $l7
          local.get $l0
          i32.const 300
          i32.add
          local.get $l1
          i32.const 1
          i32.add
          local.tee $l16
          i32.add
          local.set $l5
          i32.const 0
          local.set $l14
          (block $b75
            local.get $l15
            i32.const 0
            i32.ge_s
            br_if $b75
            local.get $l5
            i32.const 45
            i32.store8
            i32.const 1
            local.set $l14
          )
          local.get $l10
          local.get $l11
          i32.sub
          local.set $l1
          (loop $b76
            local.get $l0
            i32.const 768
            i32.add
            local.get $l7
            i32.add
            local.get $l1
            local.get $l1
            i32.const 10
            i32.div_u
            local.tee $l11
            i32.const 10
            i32.mul
            i32.sub
            i32.const 48
            i32.or
            i32.store8
            local.get $l7
            i32.const 1
            i32.add
            local.set $l7
            local.get $l1
            i32.const 9
            i32.gt_u
            local.set $l10
            local.get $l11
            local.set $l1
            local.get $l10
            br_if $b76
          )
          local.get $l5
          local.get $l14
          i32.add
          local.set $l5
          local.get $l7
          i32.const -1
          i32.add
          local.tee $l10
          local.get $l0
          i32.const 768
          i32.add
          i32.add
          local.set $l11
          i32.const 0
          local.set $l1
          (block $b77
            (loop $b78
              local.get $l1
              local.get $l10
              i32.gt_u
              br_if $b77
              local.get $l5
              local.get $l1
              i32.add
              local.get $l11
              i32.load8_u
              i32.store8
              local.get $l11
              i32.const -1
              i32.add
              local.set $l11
              local.get $l1
              i32.const 1
              i32.add
              local.set $l1
              br $b78
            )
          )
          local.get $l14
          local.get $l16
          i32.add
          local.set $l1
          local.get $l0
          i32.const 364
          i32.add
          local.set $l5
          i32.const 0
          local.set $l11
          (block $b79
            local.get $l12
            i32.const 45
            i32.ne
            br_if $b79
            local.get $l0
            i32.const 45
            i32.store8 offset=364
            i32.const 1
            local.set $l11
            local.get $l20
            local.set $l5
          )
          local.get $l1
          local.get $l7
          i32.add
          local.set $l10
          local.get $l15
          i32.const 1
          i32.add
          local.set $l1
          (block $b80
            (block $b81
              local.get $l15
              i32.const 0
              i32.ge_s
              br_if $b81
              local.get $l0
              i32.const 364
              i32.add
              local.get $l11
              i32.add
              local.tee $l7
              i32.const 48
              i32.store8
              local.get $l5
              i32.const 46
              i32.store8 offset=1
              local.get $l7
              i32.const 2
              i32.add
              local.set $l7
              local.get $l11
              local.get $l15
              i32.sub
              i32.const 1
              i32.add
              local.set $l11
              (block $b82
                (loop $b83
                  local.get $l1
                  i32.eqz
                  br_if $b82
                  local.get $l7
                  i32.const 48
                  i32.store8
                  local.get $l1
                  i32.const 1
                  i32.add
                  local.set $l1
                  local.get $l7
                  i32.const 1
                  i32.add
                  local.set $l7
                  br $b83
                )
              )
              (block $b84
                local.get $l13
                i32.eqz
                br_if $b84
                local.get $l0
                i32.const 364
                i32.add
                local.get $l11
                i32.add
                local.get $l0
                i32.const 264
                i32.add
                local.get $l13
                memory.copy
              )
              local.get $l11
              local.get $l13
              i32.add
              local.set $l7
              br $b80
            )
            (block $b85
              (block $b86
                local.get $l1
                local.get $l13
                i32.lt_u
                br_if $b86
                (block $b87
                  local.get $l13
                  i32.eqz
                  br_if $b87
                  local.get $l5
                  local.get $l0
                  i32.const 264
                  i32.add
                  local.get $l13
                  memory.copy
                )
                local.get $l1
                local.get $l13
                i32.sub
                local.set $l7
                local.get $l11
                local.get $l13
                i32.add
                local.set $l1
                (loop $b88
                  local.get $l0
                  i32.const 364
                  i32.add
                  local.get $l1
                  i32.add
                  local.set $l11
                  local.get $l7
                  i32.eqz
                  br_if $b85
                  local.get $l11
                  i32.const 48
                  i32.store8
                  local.get $l7
                  i32.const -1
                  i32.add
                  local.set $l7
                  local.get $l1
                  i32.const 1
                  i32.add
                  local.set $l1
                  br $b88
                )
              )
              (block $b89
                local.get $l1
                i32.eqz
                br_if $b89
                local.get $l5
                local.get $l0
                i32.const 264
                i32.add
                local.get $l1
                memory.copy
              )
              local.get $l0
              i32.const 364
              i32.add
              local.get $l11
              local.get $l1
              i32.add
              local.tee $l7
              i32.add
              i32.const 46
              i32.store8
              local.get $l7
              i32.const 1
              i32.add
              local.set $l7
              (block $b90
                local.get $l13
                local.get $l1
                i32.sub
                local.tee $l11
                i32.eqz
                br_if $b90
                local.get $l0
                i32.const 364
                i32.add
                local.get $l7
                i32.add
                local.get $l0
                i32.const 264
                i32.add
                local.get $l1
                i32.add
                local.get $l11
                memory.copy
              )
              local.get $l7
              local.get $l11
              i32.add
              local.set $l7
              br $b80
            )
            local.get $l11
            i32.const 12334
            i32.store16
            local.get $l1
            i32.const 2
            i32.add
            local.set $l7
          )
          local.get $l7
          local.get $l10
          local.get $l7
          local.get $l10
          i32.lt_u
          select
          local.tee $l1
          i32.eqz
          br_if $b0
          local.get $l0
          i32.const 147
          i32.add
          local.get $l0
          i32.const 300
          i32.add
          local.get $l0
          i32.const 364
          i32.add
          local.get $l7
          local.get $l10
          i32.gt_u
          select
          local.get $l1
          memory.copy
          br $b0
        )
        local.get $l7
        i32.const -1
        i32.add
        local.set $l7
        local.get $l1
        i32.const 1
        i32.add
        local.set $l1
        br $b65
      )
    )
    local.get $l2
    local.get $l1
    call $__std_f2
    local.set $l1
    local.get $l0
    i32.const 784
    i32.add
    global.set $__std_sp
    local.get $l1
  )
  (func $__std_f4 (param $p0 i64) (param $p1 i32) (param $p2 i32) (result i64)
    (local $l0 i32) (local $l1 i64)
    global.get $__std_sp
    i32.const 32
    i32.sub
    local.tee $l0
    global.set $__std_sp
    i64.const 0
    local.set $l1
    (block $b0
      local.get $p2
      i32.const 128
      i32.ge_u
      br_if $b0
      local.get $l0
      i32.const 16
      i32.add
      local.get $p1
      i64.load offset=8
      i64.const 0
      local.get $p0
      i64.const 0
      call $__std_f14
      local.get $l0
      local.get $p1
      i64.load
      i64.const 0
      local.get $p0
      i64.const 0
      call $__std_f14
      local.get $l0
      i64.load offset=8
      local.tee $l1
      local.get $l0
      i64.load offset=16
      i64.add
      local.tee $p0
      local.get $p2
      i32.const 63
      i32.and
      local.tee $p2
      i64.extend_i32_u
      i64.shr_u
      local.get $l0
      i64.load offset=24
      local.get $p0
      local.get $l1
      i64.lt_u
      i64.extend_i32_u
      i64.add
      i64.const 1
      i64.shl
      local.get $p2
      i32.const 63
      i32.xor
      i64.extend_i32_u
      i64.shl
      i64.or
      local.set $l1
    )
    local.get $l0
    i32.const 32
    i32.add
    global.set $__std_sp
    local.get $l1
  )
  (func $__std_f5 (param $p0 i64) (param $p1 i32) (result i32)
    (local $l0 i32) (local $l1 i32) (local $l2 i64)
    i32.const 0
    local.set $l0
    i32.const 0
    local.set $l1
    (loop $b0 (result i32)
      (block $b1
        (block $b2
          local.get $p0
          i64.eqz
          br_if $b2
          local.get $p0
          local.get $p0
          i64.const 5
          i64.div_u
          local.tee $l2
          i64.const 5
          i64.mul
          i64.sub
          i64.const 0
          i64.eq
          br_if $b1
          local.get $l1
          local.set $l0
        )
        local.get $l0
        local.get $p1
        i32.ge_u
        return
      )
      local.get $l1
      i32.const 1
      i32.add
      local.set $l1
      local.get $l2
      local.set $p0
      br $b0
    )
  )
  (func $__std_f6 (param $p0 i32) (param $p1 i32) (param $p2 i32)
    (local $l0 i64) (local $l1 i32) (local $l2 i32)
    local.get $p2
    i64.load
    local.set $l0
    (block $b0
      local.get $p2
      i32.load8_u offset=12
      local.tee $l1
      i32.const 1
      i32.and
      local.tee $p2
      i32.eqz
      br_if $b0
      local.get $p1
      i32.const 45
      i32.store8
    )
    local.get $p1
    local.get $p2
    i32.add
    local.set $p2
    (block $b1
      (block $b2
        local.get $l0
        i64.eqz
        br_if $b2
        local.get $p2
        i32.const 328
        i32.const 10
        i32.add
        local.tee $l2
        i32.load16_u
        i32.store16
        local.get $p2
        i32.const 2
        i32.add
        local.get $l2
        i32.const 2
        i32.add
        i32.load8_u
        i32.store8
        br $b1
      )
      local.get $p2
      i32.const 328
      i32.const 14
      i32.add
      local.tee $l2
      i32.load16_u
      i32.store16
      local.get $p2
      i32.const 2
      i32.add
      local.get $l2
      i32.const 2
      i32.add
      i32.load8_u
      i32.store8
    )
    local.get $p0
    local.get $p1
    i32.store
    local.get $p0
    i32.const 4
    i32.const 3
    local.get $l1
    i32.const 1
    i32.and
    select
    i32.store offset=4
  )
  (func $__std_f7 (param $p0 i64) (result i32)
    (block $b0
      local.get $p0
      i64.const 10000000000000000
      i64.lt_u
      br_if $b0
      i32.const 17
      return
    )
    (block $b1
      local.get $p0
      i64.const 999999999999999
      i64.le_u
      br_if $b1
      i32.const 16
      return
    )
    (block $b2
      local.get $p0
      i64.const 99999999999999
      i64.le_u
      br_if $b2
      i32.const 15
      return
    )
    (block $b3
      local.get $p0
      i64.const 9999999999999
      i64.le_u
      br_if $b3
      i32.const 14
      return
    )
    (block $b4
      local.get $p0
      i64.const 999999999999
      i64.le_u
      br_if $b4
      i32.const 13
      return
    )
    (block $b5
      local.get $p0
      i64.const 99999999999
      i64.le_u
      br_if $b5
      i32.const 12
      return
    )
    (block $b6
      local.get $p0
      i64.const 9999999999
      i64.le_u
      br_if $b6
      i32.const 11
      return
    )
    (block $b7
      local.get $p0
      i64.const 999999999
      i64.le_u
      br_if $b7
      i32.const 10
      return
    )
    (block $b8
      local.get $p0
      i64.const 99999999
      i64.le_u
      br_if $b8
      i32.const 9
      return
    )
    (block $b9
      local.get $p0
      i64.const 9999999
      i64.le_u
      br_if $b9
      i32.const 8
      return
    )
    (block $b10
      local.get $p0
      i64.const 999999
      i64.le_u
      br_if $b10
      i32.const 7
      return
    )
    (block $b11
      local.get $p0
      i64.const 99999
      i64.le_u
      br_if $b11
      i32.const 6
      return
    )
    (block $b12
      local.get $p0
      i64.const 9999
      i64.le_u
      br_if $b12
      i32.const 5
      return
    )
    (block $b13
      local.get $p0
      i64.const 999
      i64.le_u
      br_if $b13
      i32.const 4
      return
    )
    (block $b14
      local.get $p0
      i64.const 99
      i64.le_u
      br_if $b14
      i32.const 3
      return
    )
    i32.const 2
    i32.const 1
    local.get $p0
    i64.const 9
    i64.gt_u
    select
  )
  (func $__std_f8 (param $p0 i32) (param $p1 i32) (param $p2 i32)
    (local $l0 i32) (local $l1 i32) (local $l2 i64) (local $l3 i64) (local $l4 i32)
    local.get $p2
    local.get $p0
    i32.add
    i32.const -1
    i32.add
    local.set $p0
    i32.const 0
    local.set $l0
    (loop $b0
      (block $b1
        local.get $l0
        i32.const 2
        i32.add
        local.tee $l1
        local.get $p2
        i32.lt_u
        br_if $b1
        (block $b2
          (loop $b3
            local.get $l0
            local.get $p2
            i32.ge_u
            br_if $b2
            local.get $p1
            local.get $p1
            i64.load
            local.tee $l2
            i64.const 10
            i64.div_u
            local.tee $l3
            i64.store
            local.get $p0
            local.get $l2
            local.get $l3
            i64.const 10
            i64.mul
            i64.sub
            i32.wrap_i64
            i32.const 48
            i32.or
            i32.store8
            local.get $p0
            i32.const -1
            i32.add
            local.set $p0
            local.get $l0
            i32.const 1
            i32.add
            local.set $l0
            br $b3
          )
        )
        return
      )
      local.get $p1
      local.get $p1
      i64.load
      local.tee $l2
      i64.const 100
      i64.div_u
      local.tee $l3
      i64.store
      local.get $p0
      i32.const -1
      i32.add
      local.get $l2
      local.get $l3
      i64.const 100
      i64.mul
      i64.sub
      i32.wrap_i64
      local.tee $l0
      i32.const 255
      i32.and
      i32.const 10
      i32.div_u
      local.tee $l4
      i32.const 48
      i32.or
      i32.store8
      local.get $p0
      local.get $l0
      local.get $l4
      i32.const 10
      i32.mul
      i32.sub
      i32.const 48
      i32.or
      i32.store8
      local.get $p0
      i32.const -2
      i32.add
      local.set $p0
      local.get $l1
      local.set $l0
      br $b0
    )
  )
  (func $__std_f9 (param $p0 i32) (param $p1 i32) (param $p2 i32)
    (local $l0 i32) (local $l1 i32) (local $l2 i32) (local $l3 i32) (local $l4 i64) (local $l5 i32)
    global.get $__std_sp
    i32.const 16
    i32.sub
    local.tee $l0
    global.set $__std_sp
    (block $b0
      (block $b1
        local.get $p2
        br_if $b1
        local.get $p0
        i64.const 17179869184
        i64.store
        br $b0
      )
      (block $b2
        local.get $p1
        i32.load8_u
        i32.const 95
        i32.eq
        br_if $b2
        local.get $p1
        local.get $p2
        i32.add
        i32.const -1
        i32.add
        i32.load8_u
        i32.const 95
        i32.eq
        br_if $b2
        i32.const 0
        local.set $l1
        (loop $b3
          (block $b4
            (block $b5
              (block $b6
                local.get $p2
                i32.eqz
                br_if $b6
                local.get $p1
                i32.load8_u
                local.tee $l2
                i32.const 95
                i32.eq
                br_if $b4
                (block $b7
                  local.get $l2
                  i32.const -48
                  i32.add
                  i32.const 255
                  i32.and
                  local.tee $l2
                  i32.const 10
                  i32.lt_u
                  br_if $b7
                  local.get $p0
                  i32.const 4
                  i32.store16 offset=4
                  br $b0
                )
                (block $b8
                  local.get $l1
                  br_if $b8
                  i32.const 0
                  local.set $l3
                  br $b5
                )
                local.get $l0
                local.get $l1
                i64.extend_i32_s
                i64.const 10
                i64.mul
                local.tee $l4
                i64.const 32
                i64.shr_u
                i32.wrap_i64
                local.tee $l1
                local.get $l4
                i32.wrap_i64
                local.tee $l3
                i32.const 31
                i32.shr_s
                local.tee $l5
                i32.ne
                i32.store8 offset=8
                local.get $l1
                local.get $l5
                i32.eq
                br_if $b5
                local.get $p0
                i32.const 3
                i32.store16 offset=4
                br $b0
              )
              local.get $p0
              local.get $l1
              i32.store
              local.get $p0
              i32.const 0
              i32.store16 offset=4
              br $b0
            )
            local.get $l0
            local.get $l2
            i32.const 0
            i32.lt_s
            local.get $l3
            local.get $l2
            i32.add
            local.tee $l1
            local.get $l3
            i32.lt_s
            i32.xor
            local.tee $l2
            i32.store8 offset=12
            local.get $l2
            i32.eqz
            br_if $b4
            local.get $p0
            i32.const 3
            i32.store16 offset=4
            br $b0
          )
          local.get $p1
          i32.const 1
          i32.add
          local.set $p1
          local.get $p2
          i32.const -1
          i32.add
          local.set $p2
          br $b3
        )
      )
      local.get $p0
      i64.const 17179869184
      i64.store
    )
    local.get $l0
    i32.const 16
    i32.add
    global.set $__std_sp
  )
  (func $__std_f14 (param $p0 i32) (param $p1 i64) (param $p2 i64) (param $p3 i64) (param $p4 i64)
    (local $l0 i64)
    local.get $p0
    local.get $p4
    local.get $p1
    i64.mul
    local.get $p2
    local.get $p3
    i64.mul
    i64.add
    local.get $p3
    i64.const 32
    i64.shr_u
    local.tee $p2
    local.get $p1
    i64.const 32
    i64.shr_u
    local.tee $p4
    i64.mul
    i64.add
    local.get $p3
    i64.const 4294967295
    i64.and
    local.tee $p3
    local.get $p1
    i64.const 4294967295
    i64.and
    local.tee $p1
    i64.mul
    local.tee $l0
    i64.const 32
    i64.shr_u
    local.get $p3
    local.get $p4
    i64.mul
    i64.add
    local.tee $p3
    i64.const 32
    i64.shr_u
    i64.add
    local.get $p3
    i64.const 4294967295
    i64.and
    local.get $p2
    local.get $p1
    i64.mul
    i64.add
    local.tee $p1
    i64.const 32
    i64.shr_u
    i64.add
    i64.store offset=8
    local.get $p0
    local.get $p1
    i64.const 32
    i64.shl
    local.get $l0
    i64.const 4294967295
    i64.and
    i64.or
    i64.store
  )
  (func $__std_f15 (param $p0 i32) (param $p1 i64) (param $p2 i64) (param $p3 i32)
    (local $l0 i64)
    (block $b0
      (block $b1
        local.get $p3
        i32.const 63
        i32.le_s
        br_if $b1
        local.get $p2
        local.get $p3
        i32.const 63
        i32.and
        i64.extend_i32_u
        i64.shr_u
        local.set $p1
        i64.const 0
        local.set $p2
        br $b0
      )
      local.get $p3
      i32.eqz
      br_if $b0
      local.get $p2
      i32.const 0
      local.get $p3
      i32.sub
      i32.const 63
      i32.and
      i64.extend_i32_u
      i64.shl
      local.get $p1
      local.get $p3
      i64.extend_i32_u
      local.tee $l0
      i64.shr_u
      i64.or
      local.set $p1
      local.get $p2
      local.get $l0
      i64.shr_u
      local.set $p2
    )
    local.get $p0
    local.get $p1
    i64.store
    local.get $p0
    local.get $p2
    i64.store offset=8
  )
  (func $__std_f16 (param $p0 i32) (param $p1 i64) (param $p2 i64) (param $p3 i32)
    (local $l0 i64)
    (block $b0
      (block $b1
        local.get $p3
        i32.const 63
        i32.le_s
        br_if $b1
        local.get $p1
        local.get $p3
        i32.const 63
        i32.and
        i64.extend_i32_u
        i64.shl
        local.set $p2
        i64.const 0
        local.set $p1
        br $b0
      )
      local.get $p3
      i32.eqz
      br_if $b0
      local.get $p1
      i32.const 0
      local.get $p3
      i32.sub
      i32.const 63
      i32.and
      i64.extend_i32_u
      i64.shr_u
      local.get $p2
      local.get $p3
      i64.extend_i32_u
      local.tee $l0
      i64.shl
      i64.or
      local.set $p2
      local.get $p1
      local.get $l0
      i64.shl
      local.set $p1
    )
    local.get $p0
    local.get $p1
    i64.store
    local.get $p0
    local.get $p2
    i64.store offset=8
  )
)
```

----- RUN LOG -----
```logs
["plain", "say \"hi\"", "back\\slash", "two\nlines"]
top ["plain", "say \"hi\"", "back\\slash", "two\nlines"]
```
