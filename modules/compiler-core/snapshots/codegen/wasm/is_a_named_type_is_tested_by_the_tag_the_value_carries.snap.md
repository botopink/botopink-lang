----- SOURCE CODE -- main.bp
```botopink
type Person(name: string, age: i32)
type Vec(name: string, age: i32)
type Shape { Dot, Circle(radius: i32) }

fn nameOf(v: Person | Vec) -> string {
    return case v {
        Person { "person" }
        Vec { "vec" }
    };
}

fn main() {
    val u: unknown = Vec(name: "Ana", age: 30);
    @print(u is Vec);
    @print(u is Person);
    val s: unknown = Shape.Circle(radius: 4);
    @print(s is Shape);
    val d: unknown = Shape.Dot;
    @print(d is Shape);
    @print(nameOf(Person(name: "Ana", age: 30)));
    @print(nameOf(Vec(name: "Ana", age: 30)));
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\14\00\00\00R\06Person\02\04names\03agei")
  (data (i32.const 280) "\06\00\00\00person")
  (data (i32.const 292) "\11\00\00\00R\03Vec\02\04names\03agei")
  (data (i32.const 316) "\03\00\00\00vec")
  (data (i32.const 324) "\03\00\00\00Ana")
  (data (i32.const 332) "\17\00\00\00V\0cShape.Circle\01\06radiusi")
  (data (i32.const 360) "\0c\00\00\00V\tShape.Dot\00")
  (global $__heap_ptr (mut i32) (i32.const 376))
  (func $nameOf (param $v i32) (result i32)
    (local $Person i32)
    (local $Vec i32)
    (local $__case_0 i32)
    local.get $v
    local.set $__case_0
    local.get $__case_0
    i32.const 256
    i32.ge_u
    local.get $__case_0
    i32.const 4
    i32.sub
    i32.load
    i32.const 260
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $__case_0
    local.set $Person
    i32.const 280
      )
      (else
    local.get $__case_0
    i32.const 256
    i32.ge_u
    local.get $__case_0
    i32.const 4
    i32.sub
    i32.load
    i32.const 296
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $__case_0
    local.set $Vec
    i32.const 316
      )
      (else
    i32.const 0
      )
    )
      )
    )
    return
  )
  (func $main
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $u i32)
    (local $s i32)
    (local $d i32)
    (local $__mem4 i32)
    (local $__mem5 i32)
    (local $__mem6 i32)
    (local $__mem7 i32)
    (local $__mem8 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 296
    i32.store
    local.get $__mem0
    i32.const 324
    i32.store offset=4
    local.get $__mem0
    i32.const 30
    i32.store offset=8
    local.get $__mem0
    i32.const 4
    i32.add
    local.set $u
    local.get $u
    local.tee $__mem1
    i32.const 256
    i32.ge_u
    local.get $__mem1
    i32.const 4
    i32.sub
    i32.load
    i32.const 296
    i32.eq
    i32.and
    call $__print_bool
    local.get $u
    local.tee $__mem2
    i32.const 256
    i32.ge_u
    local.get $__mem2
    i32.const 4
    i32.sub
    i32.load
    i32.const 260
    i32.eq
    i32.and
    call $__print_bool
    global.get $__heap_ptr
    local.set $__mem3
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem3
    i32.const 336
    i32.store
    local.get $__mem3
    i32.const 1
    i32.store offset=4
    local.get $__mem3
    i32.const 4
    i32.store offset=8
    local.get $__mem3
    i32.const 4
    i32.add
    local.set $s
    local.get $s
    local.tee $__mem4
    i32.const 256
    i32.ge_u
    local.get $__mem4
    i32.const 4
    i32.sub
    i32.load
    i32.const 364
    i32.eq
    local.get $__mem4
    i32.const 4
    i32.sub
    i32.load
    i32.const 336
    i32.eq
    i32.or
    i32.and
    call $__print_bool
    global.get $__heap_ptr
    local.set $__mem5
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem5
    i32.const 364
    i32.store
    local.get $__mem5
    i32.const 0
    i32.store offset=4
    local.get $__mem5
    i32.const 4
    i32.add
    local.set $d
    local.get $d
    local.tee $__mem6
    i32.const 256
    i32.ge_u
    local.get $__mem6
    i32.const 4
    i32.sub
    i32.load
    i32.const 364
    i32.eq
    local.get $__mem6
    i32.const 4
    i32.sub
    i32.load
    i32.const 336
    i32.eq
    i32.or
    i32.and
    call $__print_bool
    global.get $__heap_ptr
    local.set $__mem7
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem7
    i32.const 260
    i32.store
    local.get $__mem7
    i32.const 324
    i32.store offset=4
    local.get $__mem7
    i32.const 30
    i32.store offset=8
    local.get $__mem7
    i32.const 4
    i32.add
    call $nameOf
    call $__print_str
    global.get $__heap_ptr
    local.set $__mem8
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem8
    i32.const 296
    i32.store
    local.get $__mem8
    i32.const 324
    i32.store offset=4
    local.get $__mem8
    i32.const 30
    i32.store offset=8
    local.get $__mem8
    i32.const 4
    i32.add
    call $nameOf
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
)
```

----- RUN LOG -----
```logs
true
false
true
true
person
vec
```
