----- SOURCE CODE -- main.bp
```botopink
type Shape {
    Circle(r: i32),
    Rect(w: i32, h: i32),
    Dot,
}

fn area(s: Shape) -> i32 {
    return case s {
        Circle(r) -> r * r * 3;
        Rect(w, h) -> w * h;
        Dot -> 0;
    };
}

fn name(s: Shape) -> string {
    return case s {
        Circle -> "circle";
        Rect -> "rect";
        Dot -> "dot";
    };
}

pub fn main() {
    val a = Shape.Circle(r: 2);
    val b = Shape.Rect(w: 3, h: 4);
    @print(area(a));
    @print(area(b));
    @print(area(Shape.Dot));
    @print(name(b));
    @print(a);
    @print(b);
    @print(Shape.Dot);
    @print(a == Shape.Circle(r: 2));
    @print(a == b);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $var_Shape_Circle (struct (field $f0 (mut i32))))
    (type $var_Shape_Rect (struct (field $f0 (mut i32)) (field $f1 (mut i32))))
    (type $var_Shape_Dot (struct))
  )
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $area (param $s anyref) (result i32)
    (local $r i32)
    (local $w i32)
    (local $h i32)
    (local $__case_0 anyref)
    local.get $s
    local.set $__case_0
    local.get $__case_0
    ref.test (ref null $var_Shape_Circle)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result i32)
      (then
    local.get $__case_0
    ref.cast (ref null $var_Shape_Circle)
    struct.get $var_Shape_Circle $f0
    local.set $r
    local.get $r
    local.get $r
    call $__i32_mul_chk
    i32.const 3
    call $__i32_mul_chk
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_Shape_Rect)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result i32)
      (then
    local.get $__case_0
    ref.cast (ref null $var_Shape_Rect)
    struct.get $var_Shape_Rect $f0
    local.set $w
    local.get $__case_0
    ref.cast (ref null $var_Shape_Rect)
    struct.get $var_Shape_Rect $f1
    local.set $h
    local.get $w
    local.get $h
    call $__i32_mul_chk
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_Shape_Dot)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result i32)
      (then
    i32.const 0
      )
      (else
    i32.const 0
      )
    )
      )
    )
      )
    )
    return
  )
  (func $name (param $s anyref) (result (ref null $str))
    (local $__case_0 anyref)
    local.get $s
    local.set $__case_0
    local.get $__case_0
    ref.test (ref null $var_Shape_Circle)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    global.get $__s0
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_Shape_Rect)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    global.get $__s1
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_Shape_Dot)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    global.get $__s2
      )
      (else
    ref.null $str
      )
    )
      )
    )
      )
    )
    return
  )
  (func $main (export "main")
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $a anyref)
    (local $b anyref)
    i32.const 2
    struct.new $var_Shape_Circle
    local.set $a
    i32.const 3
    i32.const 4
    struct.new $var_Shape_Rect
    local.set $b
    local.get $a
    call $area
    call $__print_i32
    local.get $b
    call $area
    call $__print_i32
    struct.new $var_Shape_Dot
    call $area
    call $__print_i32
    local.get $b
    call $name
    call $__print_str
    local.get $a
    call $__print_tagged_raw
    call $__print_nl
    local.get $b
    call $__print_tagged_raw
    call $__print_nl
    struct.new $var_Shape_Dot
    call $__print_tagged_raw
    call $__print_nl
    local.get $a
    i32.const 2
    struct.new $var_Shape_Circle
    call $__eq_Shape
    call $__print_bool
    local.get $a
    local.get $b
    call $__eq_Shape
    call $__print_bool
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__eq_Shape (param $a anyref) (param $b anyref) (result i32)
    local.get $a
    ref.test (ref null $var_Shape_Circle)
    (if
      (then
    local.get $b
    ref.test (ref null $var_Shape_Circle)
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    ref.cast (ref null $var_Shape_Circle)
    struct.get $var_Shape_Circle $f0
    local.get $b
    ref.cast (ref null $var_Shape_Circle)
    struct.get $var_Shape_Circle $f0
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    i32.const 1
    return
      )
    )
    local.get $a
    ref.test (ref null $var_Shape_Rect)
    (if
      (then
    local.get $b
    ref.test (ref null $var_Shape_Rect)
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    ref.cast (ref null $var_Shape_Rect)
    struct.get $var_Shape_Rect $f0
    local.get $b
    ref.cast (ref null $var_Shape_Rect)
    struct.get $var_Shape_Rect $f0
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    ref.cast (ref null $var_Shape_Rect)
    struct.get $var_Shape_Rect $f1
    local.get $b
    ref.cast (ref null $var_Shape_Rect)
    struct.get $var_Shape_Rect $f1
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    i32.const 1
    return
      )
    )
    local.get $a
    ref.test (ref null $var_Shape_Dot)
    (if
      (then
    local.get $b
    ref.test (ref null $var_Shape_Dot)
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    i32.const 1
    return
      )
    )
    i32.const 0
  )
  (func $__pr1 (param $v i32)
    local.get $v
    call $__print_i32_raw
  )
  (func $__pr0 (param $v (ref null $var_Shape_Circle))
    global.get $__s3
    call $__print_str_raw
    global.get $__s4
    call $__print_str_raw
    global.get $__s5
    call $__print_str_raw
    local.get $v
    struct.get $var_Shape_Circle $f0
    call $__pr1
    global.get $__s6
    call $__print_str_raw
  )
  (func $__pr2 (param $v (ref null $var_Shape_Rect))
    global.get $__s7
    call $__print_str_raw
    global.get $__s4
    call $__print_str_raw
    global.get $__s8
    call $__print_str_raw
    local.get $v
    struct.get $var_Shape_Rect $f0
    call $__pr1
    global.get $__s9
    call $__print_str_raw
    local.get $v
    struct.get $var_Shape_Rect $f1
    call $__pr1
    global.get $__s6
    call $__print_str_raw
  )
  (func $__pr3 (param $v (ref null $var_Shape_Dot))
    global.get $__s10
    call $__print_str_raw
  )
  (func $__print_tagged_raw (param $v anyref)
    local.get $v
    ref.test (ref null $var_Shape_Circle)
    (if
      (then
    local.get $v
    ref.cast (ref null $var_Shape_Circle)
    call $__pr0
    return
      )
    )
    local.get $v
    ref.test (ref null $var_Shape_Rect)
    (if
      (then
    local.get $v
    ref.cast (ref null $var_Shape_Rect)
    call $__pr2
    return
      )
    )
    local.get $v
    ref.test (ref null $var_Shape_Dot)
    (if
      (then
    local.get $v
    ref.cast (ref null $var_Shape_Dot)
    call $__pr3
    return
      )
    )
    unreachable
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
  (func $__print_str_raw (param $s (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    local.get $s
    array.len
    local.set $n
    global.get $__heap_ptr
    local.set $top
    local.get $n
    call $__alloc
    local.set $p
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $s
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
    local.get $n
    call $__write_bytes
    local.get $top
    global.set $__heap_ptr
  )
  (func $__print_str (param $s (ref null $str))
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
  (func $__i32_add_chk (param $a i32) (param $b i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.add
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.sub
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.mul
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.add
    local.set $r
    local.get $a
    local.get $r
    i64.xor
    local.get $b
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.sub
    local.set $r
    local.get $a
    local.get $b
    i64.xor
    local.get $a
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (result i64)
    (local $r i64)
    local.get $a
    i64.const -1
    i64.eq
    local.get $b
    i64.const -9223372036854775808
    i64.eq
    i32.and
    (if
      (then
        unreachable
      )
    )
    local.get $a
    local.get $b
    i64.mul
    local.set $r
    local.get $a
    i64.eqz
    i32.eqz
    (if
      (then
        local.get $r
        local.get $a
        i64.div_s
        local.get $b
        i64.ne
        (if
          (then
            unreachable
          )
        )
      )
    )
    local.get $r
  )
  (data $__d0 "circle")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "rect")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "dot")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "Shape.Circle")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "(")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "r: ")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 ")")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "Shape.Rect")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "w: ")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 ", h: ")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "Shape.Dot")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 6
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 4
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 3
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 12
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 1
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 3
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 1
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 10
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 3
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 5
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 9
    array.new_data $str $__d10
    global.set $__s10
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
12
12
0
rect
Shape.Circle(r: 2)
Shape.Rect(w: 3, h: 4)
Shape.Dot
true
false
```
