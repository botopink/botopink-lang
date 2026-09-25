----- SOURCE CODE -- main.bp
```botopink
type Ops(step: fn(n: i32) -> i32)
fn mk() -> #(value: i32, set: fn(n: i32) -> i32) {
    val value = 1;
    val set = { n -> return n * 2; };
    return #(value, set);
}
fn main() {
    val c = mk();
    @print(c.value);
    @print(c.set(9));
    val t = #(1, { n -> return n + 100; });
    @print(t._1(2));
    val o = Ops(step: { n -> return n - 1; });
    @print(o.step(10));
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (table funcref (elem $__lambda0 $__lambda1 $__lambda2))
  (data (i32.const 256) "\0c\00\00\00R\03Ops\01\04stepi")
  (global $__heap_ptr (mut i32) (i32.const 272))
  (func $mk (result i32)
    (local $__mem0 i32)
    (local $value i32)
    (local $set i32)
    (local $__mem1 i32)
    i32.const 1
    local.set $value
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
    local.set $set
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    local.get $value
    i32.store
    local.get $__mem1
    local.get $set
    i32.store offset=4
    local.get $__mem1
    return
  )
  (func $main
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $c i32)
    (local $t i32)
    (local $o i32)
    (local $__fnv0 i32)
    (local $__fnv1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__fnv2 i32)
    call $mk
    local.set $c
    local.get $c
    i32.load
    call $__print_i32
    local.get $c
    i32.load offset=4 ;; ._1
    local.set $__fnv0
    local.get $__fnv0
    i32.const 9
    local.get $__fnv0
    i32.load ;; table index
    call_indirect (param i32 i32) (result i32)
    call $__print_i32
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 1
    i32.store
    local.get $__mem0
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 1
    i32.store
    local.get $__mem1
    i32.store offset=4
    local.get $__mem0
    local.set $t
    local.get $t
    i32.load offset=4 ;; ._1
    local.set $__fnv1
    local.get $__fnv1
    i32.const 2
    local.get $__fnv1
    i32.load ;; table index
    call_indirect (param i32 i32) (result i32)
    call $__print_i32
    global.get $__heap_ptr
    local.set $__mem2
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem2
    i32.const 260
    i32.store
    local.get $__mem2
    global.get $__heap_ptr
    local.set $__mem3
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem3
    i32.const 2
    i32.store
    local.get $__mem3
    i32.store offset=4
    local.get $__mem2
    i32.const 4
    i32.add
    local.set $o
    local.get $o
    i32.load ;; .step
    local.set $__fnv2
    local.get $__fnv2
    i32.const 10
    local.get $__fnv2
    i32.load ;; table index
    call_indirect (param i32 i32) (result i32)
    call $__print_i32
  )
  (func $__lambda0 (param $__env i32) (param $n i32) (result i32)
    local.get $n
    i32.const 2
    i32.mul
    return
  )
  (func $__lambda1 (param $__env i32) (param $n i32) (result i32)
    local.get $n
    i32.const 100
    i32.add
    return
  )
  (func $__lambda2 (param $__env i32) (param $n i32) (result i32)
    local.get $n
    i32.const 1
    i32.sub
    return
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
)
```

----- RUN LOG -----
```logs
1
18
102
9
```
