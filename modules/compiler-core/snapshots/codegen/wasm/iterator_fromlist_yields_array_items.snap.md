----- SOURCE CODE -- main.bp
```botopink
#[@iterator]
fn fromList<T>(xs: Array<T>) -> @Iterator<T> {
    loop (xs) { item ->
        yield item;
    };
}

fn toList<T>(iter: @Iterator<T>) -> Array<T> {
    var out = [];
    loop (iter) { item ->
        out.push(item);
    };
    return out;
}

fn main() {
    @print(toList(fromList([1, 2, 3])).join(","));
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\01\00\00\00,")
  (global $__heap_ptr (mut i32) (i32.const 264))
  ;; #[@future] / #[@futureGenerator] — eager lowering
  (func $fromList (param $xs i32) (result i32)
    (local $item i32)
    (local $__yield_fn i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    i32.const 0
    call $__arr_new
    local.set $__yield_fn
    local.get $xs
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
        local.set $item
    local.get $__yield_fn
    local.get $item
    call $__arr_push
    local.set $__yield_fn
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $__yield_fn ;; everything the body yielded
  )
  (func $toList (param $iter i32) (result i32)
    (local $__mem0 i32)
    (local $out i32)
    (local $item i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
    local.set $out
    local.get $iter
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
        local.set $item
    local.get $out
    local.get $item
    call $__arr_push
    local.set $out
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $out
    return
  )
  (func $main
    (local $__mem0 i32)
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
    i32.const 1
    i32.store offset=4
    local.get $__mem0
    i32.const 2
    i32.store offset=8
    local.get $__mem0
    i32.const 3
    i32.store offset=12
    local.get $__mem0
    call $fromList
    call $toList
    i32.const 256
    call $__arr_join_i32
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
  (func $__i32_to_str (param $n i32) (result i32)
    (local $u i64) (local $pos i32) (local $len i32) (local $p i32) (local $neg i32)
    i32.const 160
    local.set $pos
    local.get $n
    i32.const 0
    i32.lt_s
    local.set $neg
    local.get $n
    i64.extend_i32_s
    local.set $u
    local.get $neg
    (if
      (then
        i64.const 0
        local.get $u
        i64.sub
        local.set $u
      )
    )
    (block $brk
      (loop $cont
        local.get $pos
        i32.const 1
        i32.sub
        local.set $pos
        local.get $pos
        local.get $u
        i64.const 10
        i64.rem_u
        i32.wrap_i64
        i32.const 48
        i32.add
        i32.store8
        local.get $u
        i64.const 10
        i64.div_u
        local.set $u
        local.get $u
        i64.eqz
        br_if $brk
        br $cont
      )
    )
    local.get $neg
    (if
      (then
        local.get $pos
        i32.const 1
        i32.sub
        local.set $pos
        local.get $pos
        i32.const 45
        i32.store8
      )
    )
    i32.const 160
    local.get $pos
    i32.sub
    local.set $len
    local.get $len
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $len
    i32.store
    local.get $p
    i32.const 4
    i32.add
    local.get $pos
    local.get $len
    memory.copy
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
  (func $__arr_join_i32 (param $xs i32) (param $sep i32) (result i32)
    (local $n i32) (local $i i32) (local $t i32)
    local.get $xs
    i32.load
    local.set $n
    local.get $n
    call $__arr_new
    local.set $t
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $t
        i32.const 4
        i32.add
        local.get $i
        i32.const 4
        i32.mul
        i32.add
        local.get $xs
        i32.const 4
        i32.add
        local.get $i
        i32.const 4
        i32.mul
        i32.add
        i32.load
        call $__i32_to_str
        i32.store
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $t
    local.get $sep
    call $__arr_join_str
  )
)
```

----- RUN LOG -----
```logs
1,2,3
```
