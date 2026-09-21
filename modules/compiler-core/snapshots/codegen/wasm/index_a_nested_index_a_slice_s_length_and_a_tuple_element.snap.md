----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val rows = [[1, 2], [3, 4]];
    @print(rows);
    @print(rows[1]);
    @print(rows[1][0]);
    @print(rows[0].length);
    val xs = [10, 20, 30];
    @print(xs[0..2].length);
    val sl = xs[0..2];
    @print(sl.length);
    val ps = [#(1, "a"), #(2, "b")];
    @print(ps[1]);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\03\00\00\00[[i")
  (data (i32.const 264) "\01\00\00\00a")
  (data (i32.const 272) "\01\00\00\00b")
  (global $__heap_ptr (mut i32) (i32.const 280))
  (func $main
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    (local $__mem5 i32)
    (local $__mem6 i32)
    (local $rows i32)
    (local $xs i32)
    (local $sl i32)
    (local $ps i32)
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
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 2
    i32.store
    local.get $__mem1
    i32.const 1
    i32.store offset=4
    local.get $__mem1
    i32.const 2
    i32.store offset=8
    local.get $__mem1
    i32.store offset=4
    local.get $__mem0
    global.get $__heap_ptr
    local.set $__mem2
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem2
    i32.const 2
    i32.store
    local.get $__mem2
    i32.const 3
    i32.store offset=4
    local.get $__mem2
    i32.const 4
    i32.store offset=8
    local.get $__mem2
    i32.store offset=8
    local.get $__mem0
    local.set $rows
    local.get $rows
    i32.const 260
    i32.const 1
    call $__print_shaped_raw
    drop
    call $__print_nl
    local.get $rows
    i32.const 1
    call $__arr_at_box
    call $__print_opt_i32
    local.get $rows
    i32.const 1
    call $__arr_at_box
    i32.const 0
    call $__arr_at
    call $__print_i32
    i32.const 0 ;; field access .length (unknown receiver type)
    call $__print_i32
    global.get $__heap_ptr
    local.set $__mem3
    global.get $__heap_ptr
    i32.const 16
    i32.add
    global.set $__heap_ptr
    local.get $__mem3
    i32.const 3
    i32.store
    local.get $__mem3
    i32.const 10
    i32.store offset=4
    local.get $__mem3
    i32.const 20
    i32.store offset=8
    local.get $__mem3
    i32.const 30
    i32.store offset=12
    local.get $__mem3
    local.set $xs
    local.get $xs
    i32.const 0
    i32.const 2
    call $__arr_slice
    i32.load ;; .length
    call $__print_i32
    local.get $xs
    i32.const 0
    i32.const 2
    call $__arr_slice
    local.set $sl
    local.get $sl
    i32.load ;; .length
    call $__print_i32
    global.get $__heap_ptr
    local.set $__mem4
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem4
    i32.const 2
    i32.store
    local.get $__mem4
    global.get $__heap_ptr
    local.set $__mem5
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem5
    i32.const 1
    i32.store
    local.get $__mem5
    i32.const 264
    i32.store offset=4
    local.get $__mem5
    i32.store offset=4
    local.get $__mem4
    global.get $__heap_ptr
    local.set $__mem6
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem6
    i32.const 2
    i32.store
    local.get $__mem6
    i32.const 272
    i32.store offset=4
    local.get $__mem6
    i32.store offset=8
    local.get $__mem4
    local.set $ps
    local.get $ps
    i32.const 1
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
    (local $i i32) (local $frac f64) (local $d i32) (local $k i32) (local $last i32)
    local.get $x
    f64.const 0
    f64.lt
    (if
      (then
        i32.const 32
        i32.const 45
        i32.store8
        i32.const 32
        i32.const 1
        call $__write_bytes
        local.get $x
        f64.neg
        local.set $x
      )
    )
    local.get $x
    i32.trunc_f64_s
    local.set $i
    local.get $x
    local.get $i
    f64.convert_i32_s
    f64.sub
    local.set $frac
    local.get $i
    call $__print_i32_raw
    ;; fractional digits into 34.. ; 33 holds the '.'
    i32.const 0
    local.set $k
    i32.const 0
    local.set $last
    (block $fdone
      (loop $fdigits
        local.get $k
        i32.const 6
        i32.ge_s
        br_if $fdone
        local.get $frac
        f64.const 10
        f64.mul
        local.set $frac
        local.get $frac
        i32.trunc_f64_s
        local.set $d
        local.get $frac
        local.get $d
        f64.convert_i32_s
        f64.sub
        local.set $frac
        i32.const 34
        local.get $k
        i32.add
        local.get $d
        i32.const 48
        i32.add
        i32.store8
        local.get $k
        i32.const 1
        i32.add
        local.set $k
        local.get $d
        (if
          (then
            local.get $k
            local.set $last
          )
        )
        br $fdigits
      )
    )
    ;; §7 F5: an f64 always carries its decimal part — `5.0`, never `5`
    local.get $last
    i32.eqz
    (if
      (then
        i32.const 1
        local.set $last
      )
    )
    local.get $last
    (if
      (then
        i32.const 33
        i32.const 46
        i32.store8
        i32.const 33
        local.get $last
        i32.const 1
        i32.add
        call $__write_bytes
      )
    )
  )
  (func $__arr_at (param $xs i32) (param $i i32) (result i32)
    local.get $i
    i32.const 0
    i32.lt_s
    local.get $i
    local.get $xs
    i32.load
    i32.ge_s
    i32.or
    (if (result i32)
      (then i32.const 0)
      (else
        local.get $xs
        local.get $i
        i32.const 1
        i32.add
        i32.const 4
        i32.mul
        i32.add
        i32.load
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
  (func $__arr_slice (param $xs i32) (param $a i32) (param $b i32) (result i32)
    (local $n i32) (local $cnt i32) (local $p i32)
    local.get $xs
    i32.load
    local.set $n
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $n
        local.get $a
        i32.add
        local.set $a
        local.get $a
        i32.const 0
        i32.lt_s
        (if
          (then
            i32.const 0
            local.set $a
          )
        )
      )
      (else
        local.get $a
        local.get $n
        i32.gt_s
        (if
          (then
            local.get $n
            local.set $a
          )
        )
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $n
        local.get $b
        i32.add
        local.set $b
        local.get $b
        i32.const 0
        i32.lt_s
        (if
          (then
            i32.const 0
            local.set $b
          )
        )
      )
      (else
        local.get $b
        local.get $n
        i32.gt_s
        (if
          (then
            local.get $n
            local.set $b
          )
        )
      )
    )
    local.get $b
    local.get $a
    i32.sub
    local.set $cnt
    local.get $cnt
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 0
        local.set $cnt
      )
    )
    local.get $cnt
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $xs
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.mul
    i32.add
    local.get $cnt
    i32.const 4
    i32.mul
    memory.copy
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
  (func $__print_undefined
    i32.const 176
    i64.const 7308895133777555061
    i64.store
    i32.const 184
    i32.const 100
    i32.store8
    i32.const 176
    i32.const 9
    call $__write_bytes
  )
  (func $__print_opt_i32_raw (param $p i32)
    local.get $p
    i32.eqz
    (if
      (then
        call $__print_undefined
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
        call $__print_undefined
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
        call $__print_undefined
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
            f32.reinterpret_i32
            f64.promote_f32
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
)
```

----- RUN LOG -----
```logs
[[1, 2], [3, 4]]
304
0
0
2
2
384
```
