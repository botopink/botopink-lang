----- SOURCE CODE -- main.bp
```botopink
type Box(items: Array<i32>) {
    fn total(self: Self) -> i32 {
        var sum = 0;
        self.items.forEach({ n -> sum = sum + n });
        return sum;
    }
    fn isBig(self: Self) -> bool { return self.items.length > 1; }
    fn doubled(self: Self) -> Array<i32> { return self.items.map({ n -> n * 2 }); }
    fn label(self: Self) -> string { return "box"; }
}
fn main() {
    var seen = 0;
    [1, 2].forEach({ n -> seen = n });
    @print(seen);
    val b = Box(items: [3, 4]);
    @print(b.total());
    var h: ?i32 = null;
    @print(h);
    h = 5;
    @print(h);
    var acc: ?i32 = null;
    [7, 8].forEach({ n -> acc = n });
    @print(acc);
    @print(b.isBig());
    @print(b.doubled());
    @print(b.label());
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\03\00\00\00box")
  (data (i32.const 264) "\0d\00\00\00R\03Box\01\05itemsi")
  (global $__heap_ptr (mut i32) (i32.const 284))
  (func $Box_total (param $self i32) (result i32)
    (local $sum i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $n i32)
    i32.const 0
    local.set $sum
    local.get $self
    i32.load ;; .items
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
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
        local.set $n
    local.get $sum
    local.get $n
    i32.add
    local.set $sum
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $sum
    return
  )
  (func $Box_isBig (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    i32.load ;; .length
    i32.const 1
    i32.gt_s
    return
  )
  (func $Box_doubled (param $self i32) (result i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $__out0 i32)
    (local $n i32)
    local.get $self
    i32.load ;; .items
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    call $__arr_new
    local.set $__out0
    i32.const 0
    local.set $__acc0
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
        local.set $n
    local.get $__out0
    local.get $__idx0
    i32.const 4
    i32.mul
    i32.add
    local.get $n
    i32.const 2
    i32.mul
    i32.store offset=4
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    return
  )
  (func $Box_label (param $self i32) (result i32)
    i32.const 256
    return
  )
  (func $main
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $seen i32)
    (local $b i32)
    (local $h i32)
    (local $acc i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $n i32)
    (local $__iter1 i32)
    (local $__idx1 i32)
    (local $__len1 i32)
    (local $__acc1 i32)
    i32.const 0
    local.set $seen
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
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
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
        local.set $n
    local.get $n
    local.set $seen
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $seen
    call $__print_i32
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 268
    i32.store
    local.get $__mem1
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
    i32.store offset=4
    local.get $__mem1
    i32.const 4
    i32.add
    local.set $b
    local.get $b
    call $Box_total
    call $__print_i32
    i32.const 0
    local.set $h
    local.get $h
    call $__print_opt_i32
    i32.const 5
    call $__box_i32
    local.set $h
    local.get $h
    call $__print_opt_i32
    i32.const 0
    local.set $acc
    global.get $__heap_ptr
    local.set $__mem3
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem3
    i32.const 2
    i32.store
    local.get $__mem3
    i32.const 7
    i32.store offset=4
    local.get $__mem3
    i32.const 8
    i32.store offset=8
    local.get $__mem3
    local.set $__iter1
    local.get $__iter1
    i32.load ;; element count
    local.set $__len1
    i32.const 0
    local.set $__idx1
    i32.const 0
    local.set $__acc1
    (block $__break
      (loop $__continue
        local.get $__idx1
        local.get $__len1
        i32.ge_s
        br_if $__break
        local.get $__iter1
        local.get $__idx1
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $n
    local.get $n
    call $__box_i32
    local.set $acc
        local.get $__idx1
        i32.const 1
        i32.add
        local.set $__idx1
        br $__continue
      )
    )
    local.get $acc
    call $__print_opt_i32
    local.get $b
    call $Box_isBig
    call $__print_bool
    local.get $b
    call $Box_doubled
    call $__print_arr_i32
    local.get $b
    call $Box_label
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
)
```

----- RUN LOG -----
```logs
2
7
undefined
5
8
true
[6, 8]
box
```
