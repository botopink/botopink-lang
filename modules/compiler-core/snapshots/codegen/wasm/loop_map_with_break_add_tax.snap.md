----- SOURCE CODE -- main.bp
```botopink
val precosBrutos = [100, 250, 400];
val precosComTaxa = loop (precosBrutos) { valor ->
    val taxa = valor * 0.15;
    break valor + taxa;
};
fn main() {
    @print(precosComTaxa);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (start $__init_globals)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $precosBrutos (mut i32) (i32.const 0))
  (global $precosComTaxa (mut i32) (i32.const 0))
  (func $main
    global.get $precosComTaxa
    call $__print_arr_f32
  )
  (func $__init_globals
    (local $__mem0 i32)
    (local $__yield0 i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $valor i32)
    (local $taxa f32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 16
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 3
    i32.store
    local.get $__mem0
    i32.const 100
    i32.store offset=4
    local.get $__mem0
    i32.const 250
    i32.store offset=8
    local.get $__mem0
    i32.const 400
    i32.store offset=12
    local.get $__mem0
    global.set $precosBrutos
    i32.const 0
    call $__arr_new
    local.set $__yield0
    global.get $precosBrutos
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $valor
    local.get $valor
    f32.convert_i32_s
    f32.const 0.15
    f32.mul
    local.set $taxa
    local.get $__yield0
    local.get $valor
    f32.convert_i32_s
    local.get $taxa
    f32.add
    i32.reinterpret_f32
    call $__arr_push
    local.set $__yield0
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__yield0
    global.set $precosComTaxa
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
  (func $__arr_push (param $xs i32) (param $x i32) (result i32)
    (local $n i32) (local $p i32)
    local.get $xs
    i32.load
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $xs
    i32.const 4
    i32.add
    local.get $n
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
    i32.const 4
    i32.add
    local.get $n
    i32.const 4
    i32.mul
    i32.add
    local.get $x
    i32.store
    local.get $p
  )
  (func $__print_arr_f32_raw (param $xs i32)
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
            i32.const 1
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
        f32.load
        f64.promote_f32
        call $__print_f64_raw
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
  (func $__print_arr_f32 (param $xs i32)
    local.get $xs
    call $__print_arr_f32_raw
    call $__print_nl
  )
)
```

----- RUN LOG -----
```logs
[115.0,287.5,460.0]
```
