----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val a = #(1, "a");
    val b = #(1, "a");
    @print(a == b);
    @print(a != b);
    val c = #(1, "b");
    @print(a == c);
    val name = "SP";
    val pop = 12;
    val labeled = #(name, pop);
    val plain = #("SP", 12);
    @print(labeled == plain);
    val n1 = #(#(1, 2), "x");
    val n2 = #(#(1, 2), "x");
    val n3 = #(#(1, 3), "x");
    @print(n1 == n2);
    @print(n1 == n3);
    val f1 = #(1.5, true);
    val f2 = #(1.5, true);
    val f3 = #(1.5, false);
    @print(f1 == f2);
    @print(f1 == f3);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\01\00\00\00a")
  (data (i32.const 264) "\01\00\00\00b")
  (data (i32.const 272) "\02\00\00\00SP")
  (data (i32.const 280) "\01\00\00\00x")
  (global $__heap_ptr (mut i32) (i32.const 288))
  (func $main
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    (local $__mem5 i32)
    (local $__mem6 i32)
    (local $__mem7 i32)
    (local $__mem8 i32)
    (local $__mem9 i32)
    (local $__mem10 i32)
    (local $__mem11 i32)
    (local $__mem12 i32)
    (local $__mem13 i32)
    (local $a i32)
    (local $b i32)
    (local $c i32)
    (local $name i32)
    (local $pop i32)
    (local $labeled i32)
    (local $plain i32)
    (local $n1 i32)
    (local $n2 i32)
    (local $n3 i32)
    (local $f1 i32)
    (local $f2 i32)
    (local $f3 i32)
    (local $_res0 i32)
    (local $_res1 i32)
    (local $_res2 i32)
    (local $_res3 i32)
    (local $_res4 i32)
    (local $_res5 i32)
    (local $_res6 i32)
    (local $_res7 i32)
    (local $_res8 i32)
    (local $_res9 i32)
    (local $_res10 i32)
    (local $_res11 i32)
    (local $_res12 i32)
    (local $_res13 i32)
    (local $_res14 i32)
    (local $_res15 i32)
    (local $_res16 i32)
    (local $_res17 i32)
    (local $_res18 i32)
    (local $_res19 i32)
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
    i32.const 256
    i32.store offset=4
    local.get $__mem0
    local.set $a
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
    i32.const 256
    i32.store offset=4
    local.get $__mem1
    local.set $b
    local.get $a
    local.set $_res0
    local.get $b
    local.set $_res1
    local.get $_res0
    i32.load
    local.get $_res1
    i32.load
    i32.eq
    local.get $_res0
    i32.load offset=4
    local.get $_res1
    i32.load offset=4
    call $__str_eq
    i32.and
    call $__print_bool
    local.get $a
    local.set $_res2
    local.get $b
    local.set $_res3
    local.get $_res2
    i32.load
    local.get $_res3
    i32.load
    i32.eq
    local.get $_res2
    i32.load offset=4
    local.get $_res3
    i32.load offset=4
    call $__str_eq
    i32.and
    i32.eqz
    call $__print_bool
    global.get $__heap_ptr
    local.set $__mem2
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem2
    i32.const 1
    i32.store
    local.get $__mem2
    i32.const 264
    i32.store offset=4
    local.get $__mem2
    local.set $c
    local.get $a
    local.set $_res4
    local.get $c
    local.set $_res5
    local.get $_res4
    i32.load
    local.get $_res5
    i32.load
    i32.eq
    local.get $_res4
    i32.load offset=4
    local.get $_res5
    i32.load offset=4
    call $__str_eq
    i32.and
    call $__print_bool
    i32.const 272
    local.set $name
    i32.const 12
    local.set $pop
    global.get $__heap_ptr
    local.set $__mem3
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem3
    local.get $name
    i32.store
    local.get $__mem3
    local.get $pop
    i32.store offset=4
    local.get $__mem3
    local.set $labeled
    global.get $__heap_ptr
    local.set $__mem4
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem4
    i32.const 272
    i32.store
    local.get $__mem4
    i32.const 12
    i32.store offset=4
    local.get $__mem4
    local.set $plain
    local.get $labeled
    local.set $_res6
    local.get $plain
    local.set $_res7
    local.get $_res6
    i32.load
    local.get $_res7
    i32.load
    call $__str_eq
    local.get $_res6
    i32.load offset=4
    local.get $_res7
    i32.load offset=4
    i32.eq
    i32.and
    call $__print_bool
    global.get $__heap_ptr
    local.set $__mem5
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem5
    global.get $__heap_ptr
    local.set $__mem6
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem6
    i32.const 1
    i32.store
    local.get $__mem6
    i32.const 2
    i32.store offset=4
    local.get $__mem6
    i32.store
    local.get $__mem5
    i32.const 280
    i32.store offset=4
    local.get $__mem5
    local.set $n1
    global.get $__heap_ptr
    local.set $__mem7
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem7
    global.get $__heap_ptr
    local.set $__mem8
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem8
    i32.const 1
    i32.store
    local.get $__mem8
    i32.const 2
    i32.store offset=4
    local.get $__mem8
    i32.store
    local.get $__mem7
    i32.const 280
    i32.store offset=4
    local.get $__mem7
    local.set $n2
    global.get $__heap_ptr
    local.set $__mem9
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem9
    global.get $__heap_ptr
    local.set $__mem10
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem10
    i32.const 1
    i32.store
    local.get $__mem10
    i32.const 3
    i32.store offset=4
    local.get $__mem10
    i32.store
    local.get $__mem9
    i32.const 280
    i32.store offset=4
    local.get $__mem9
    local.set $n3
    local.get $n1
    local.set $_res8
    local.get $n2
    local.set $_res9
    local.get $_res8
    i32.load
    local.set $_res10
    local.get $_res9
    i32.load
    local.set $_res11
    local.get $_res10
    i32.load
    local.get $_res11
    i32.load
    i32.eq
    local.get $_res10
    i32.load offset=4
    local.get $_res11
    i32.load offset=4
    i32.eq
    i32.and
    local.get $_res8
    i32.load offset=4
    local.get $_res9
    i32.load offset=4
    call $__str_eq
    i32.and
    call $__print_bool
    local.get $n1
    local.set $_res12
    local.get $n3
    local.set $_res13
    local.get $_res12
    i32.load
    local.set $_res14
    local.get $_res13
    i32.load
    local.set $_res15
    local.get $_res14
    i32.load
    local.get $_res15
    i32.load
    i32.eq
    local.get $_res14
    i32.load offset=4
    local.get $_res15
    i32.load offset=4
    i32.eq
    i32.and
    local.get $_res12
    i32.load offset=4
    local.get $_res13
    i32.load offset=4
    call $__str_eq
    i32.and
    call $__print_bool
    global.get $__heap_ptr
    local.set $__mem11
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem11
    f64.const 1.5
    f32.demote_f64
    f32.store
    local.get $__mem11
    i32.const 1
    i32.store offset=4
    local.get $__mem11
    local.set $f1
    global.get $__heap_ptr
    local.set $__mem12
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem12
    f64.const 1.5
    f32.demote_f64
    f32.store
    local.get $__mem12
    i32.const 1
    i32.store offset=4
    local.get $__mem12
    local.set $f2
    global.get $__heap_ptr
    local.set $__mem13
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem13
    f64.const 1.5
    f32.demote_f64
    f32.store
    local.get $__mem13
    i32.const 0
    i32.store offset=4
    local.get $__mem13
    local.set $f3
    local.get $f1
    local.set $_res16
    local.get $f2
    local.set $_res17
    local.get $_res16
    f32.load
    local.get $_res17
    f32.load
    f32.eq
    local.get $_res16
    i32.load offset=4
    local.get $_res17
    i32.load offset=4
    i32.eq
    i32.and
    call $__print_bool
    local.get $f1
    local.set $_res18
    local.get $f3
    local.set $_res19
    local.get $_res18
    f32.load
    local.get $_res19
    f32.load
    f32.eq
    local.get $_res18
    i32.load offset=4
    local.get $_res19
    i32.load offset=4
    i32.eq
    i32.and
    call $__print_bool
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
  (func $__str_eq (param $a i32) (param $b i32) (result i32)
    (local $i i32) (local $alen i32)
    local.get $a
    i32.load
    local.set $alen
    local.get $alen
    local.get $b
    i32.load
    i32.ne
    (if
      (then i32.const 0 return)
    )
    (block $done
      (loop $cmp
        local.get $i
        local.get $alen
        i32.ge_u
        br_if $done
        local.get $a
        local.get $i
        i32.add
        i32.load8_u offset=4
        local.get $b
        local.get $i
        i32.add
        i32.load8_u offset=4
        i32.ne
        (if
          (then i32.const 0 return)
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cmp
      )
    )
    i32.const 1
  )
)
```

----- RUN LOG -----
```logs
true
false
false
true
true
false
true
false
```
