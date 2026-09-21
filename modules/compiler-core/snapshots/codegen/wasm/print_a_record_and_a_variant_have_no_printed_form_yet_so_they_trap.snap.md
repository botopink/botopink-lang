----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
type Shape { Square(side: i32), Nothing }
fn main() {
    @print("hi");
    @print([1, 2]);
    @print(#(1, "a"));
    @print(Point(x: 1, y: 2));
    @print(Shape.Square(side: 4));
    @print(Shape.Nothing);
    @print([Point(x: 1, y: 2)]);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\02\00\00\00hi")
  (data (i32.const 264) "\01\00\00\00a")
  (data (i32.const 272) "\04\00\00\00(is)")
  (data (i32.const 280) "\0e\00\00\00R\05Point\02\01xi\01yi")
  (data (i32.const 300) "\15\00\00\00V\0cShape.Square\01\04sidei")
  (data (i32.const 328) "\10\00\00\00V\rShape.Nothing\00")
  (data (i32.const 348) "\02\00\00\00[T")
  (global $__heap_ptr (mut i32) (i32.const 356))
  (func $main
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    (local $__mem5 i32)
    (local $__mem6 i32)
    i32.const 256
    call $__print_str
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
    i32.const 1
    i32.store offset=4
    local.get $__mem0
    i32.const 2
    i32.store offset=8
    local.get $__mem0
    call $__print_arr_i32
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
    i32.const 264
    i32.store offset=4
    local.get $__mem1
    i32.const 276
    i32.const 1
    call $__print_shaped_raw
    drop
    call $__print_nl
    global.get $__heap_ptr
    local.set $__mem2
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem2
    i32.const 284
    i32.store
    local.get $__mem2
    i32.const 1
    i32.store offset=4
    local.get $__mem2
    i32.const 2
    i32.store offset=8
    local.get $__mem2
    i32.const 4
    i32.add
    call $__print_tagged
    global.get $__heap_ptr
    local.set $__mem3
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem3
    i32.const 304
    i32.store
    local.get $__mem3
    i32.const 0
    i32.store offset=4
    local.get $__mem3
    i32.const 4
    i32.store offset=8
    local.get $__mem3
    i32.const 4
    i32.add
    call $__print_tagged
    global.get $__heap_ptr
    local.set $__mem4
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem4
    i32.const 332
    i32.store
    local.get $__mem4
    i32.const 1
    i32.store offset=4
    local.get $__mem4
    i32.const 4
    i32.add
    call $__print_tagged
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
    global.get $__heap_ptr
    local.set $__mem6
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem6
    i32.const 284
    i32.store
    local.get $__mem6
    i32.const 1
    i32.store offset=4
    local.get $__mem6
    i32.const 2
    i32.store offset=8
    local.get $__mem6
    i32.const 4
    i32.add
    i32.store offset=4
    local.get $__mem5
    i32.const 352
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
  (func $__print_arr_i32_raw (param $xs i32)
    (local $n i32) (local $i i32)
    i32.const 8
    i32.const 91
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
    local.get $xs
    i32.load
    local.set $n
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
        local.get $xs
        i32.const 4
        i32.add
        local.get $i
        i32.const 4
        i32.mul
        i32.add
        i32.load
        call $__print_i32_raw
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    i32.const 8
    i32.const 93
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_arr_i32 (param $xs i32)
    local.get $xs
    call $__print_arr_i32_raw
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
  (func $__print_tagged_raw (param $v i32)
    (local $d i32) (local $p i32) (local $k i32) (local $i i32) (local $n i32) (local $b i32)
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
hi
[1, 2]
#(1, "a")
Point(x: 1, y: 2)
Shape.Square(side: 4)
Shape.Nothing
[Point(x: 1, y: 2)]
```
