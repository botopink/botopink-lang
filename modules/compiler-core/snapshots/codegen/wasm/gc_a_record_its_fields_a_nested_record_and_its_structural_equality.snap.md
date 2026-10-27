----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
type Person(name: string, age: i32, tall: bool, h: f64, home: Point)

fn sum(p: Point) -> i32 {
    return p.x + p.y;
}

fn greet(p: Person) -> string {
    return "hi " + p.name;
}

pub fn main() -> void {
    val p = Point(x: 1, y: 2);
    print(sum(p));
    print(p);
    val q = Person(name: "Ana", age: 30, tall: true, h: 1.75, home: p);
    print(greet(q));
    print(q);
    print(q.home.y);
    print(q.h);
    print(q.tall);
    print(p == Point(x: 1, y: 2));
    print(p == Point(x: 1, y: 3));
}

import {io.terminal.print} from "std";
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_i32 (array (mut i32)))
    (type $arr_f64 (array (mut f64)))
    (type $arr_any (sub (array (mut anyref))))
    (type $tuple (sub final $arr_any (array (mut anyref))))
    (type $box_i32 (sub (struct (field $v i32))))
    (type $box_i64 (struct (field $v i64)))
    (type $box_f64 (struct (field $v f64)))
    (type $box_bool (sub final $box_i32 (struct (field $v i32))))
    (type $closure (sub (struct (field $idx i32) (field $mark i32))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $exn (struct (field $msg (ref null $str)) (field $print i32)))
    (type $task (struct (field $state (mut i32)) (field $waiters (mut (ref null $waiter))) (field $value (mut anyref)) (field $frame (mut structref)) (field $kind i32) (field $next (mut (ref null $task))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $waiter (struct (field $next (mut (ref null $waiter))) (field $kind i32) (field $target (ref null $task)) (field $slot i32)))
    (type $hostn (struct (field $next (mut (ref null $hostn))) (field $h i32) (field $t (ref null $task))))
    (type $gen (struct (field $state (mut i32)) (field $kind i32) (field $frame (mut structref)) (field $value (mut anyref)) (field $src (mut (ref null $gen))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $cell (struct (field $filled (mut i32)) (field $value (mut anyref))))
  )
  (rec
    (type $rec_Point (struct (field $f0 (mut i32)) (field $f1 (mut i32))))
    (type $brand_rec_Point (struct (field i64) (field i64) (field i64) (field f64) (field i64) (field f64) (field i64) (field i64) (field i32) (field f64) (field f32) (field f64) (field i32) (field i64) (field f32) (field f32) (field i64) (field i64) (field i64) (field i32) (field i32) (field f32) (field f64) (field f64) (field i32) (field i32) (field i32) (field f64) (field f32) (field f32) (field f32) (field f32)))
  )
  (rec
    (type $rec_Person (struct (field $f0 (mut (ref null $str))) (field $f1 (mut i32)) (field $f2 (mut i32)) (field $f3 (mut f64)) (field $f4 (mut (ref null $rec_Point)))))
    (type $brand_rec_Person (struct (field f64) (field i64) (field f64) (field f64) (field i64) (field i32) (field f32) (field f32) (field i64) (field f32) (field f32) (field f32) (field i64) (field i64) (field i32) (field i32) (field f64) (field i32) (field f32) (field f64) (field i64) (field f64) (field i32) (field i32) (field f32) (field f32) (field i64) (field i32) (field i64) (field i64) (field f32) (field i64)))
  )
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@number" "wat:number.i64ToString" (func $__std_number_i64ToString (param i64) (result (ref null $str))))
  (import "std@number" "wat:number.u64ToString" (func $__std_number_u64ToString (param i64) (result (ref null $str))))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $sum (param $p (ref null $rec_Point)) (result i32)
    local.get $p
    struct.get $rec_Point $f0
    local.get $p
    struct.get $rec_Point $f1
    global.get $__s0
    call $__i32_add_chk
    return
  )
  (func $greet (param $p (ref null $rec_Person)) (result (ref null $str))
    global.get $__s1
    local.get $p
    struct.get $rec_Person $f0
    call $__str_concat
    return
  )
  (func $main (export "main")
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $p (ref null $rec_Point))
    (local $q (ref null $rec_Person))
    i32.const 1
    i32.const 2
    struct.new $rec_Point
    local.set $p
    local.get $p
    call $sum
    call $__print_i32
    local.get $p
    call $__pr0
    call $__print_nl
    global.get $__s7
    i32.const 30
    i32.const 1
    f64.const 1.75
    local.get $p
    struct.new $rec_Person
    local.set $q
    local.get $q
    call $greet
    call $__print_str
    local.get $q
    call $__pr2
    call $__print_nl
    local.get $q
    struct.get $rec_Person $f4
    struct.get $rec_Point $f1
    call $__print_i32
    local.get $q
    struct.get $rec_Person $f3
    call $__print_f64
    local.get $q
    struct.get $rec_Person $f2
    call $__print_bool
    local.get $p
    i32.const 1
    i32.const 2
    struct.new $rec_Point
    call $__eq_Point
    call $__print_bool
    local.get $p
    i32.const 1
    i32.const 3
    struct.new $rec_Point
    call $__eq_Point
    call $__print_bool
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__eq_Point (param $a (ref null $rec_Point)) (param $b (ref null $rec_Point)) (result i32)
    local.get $a
    struct.get $rec_Point $f0
    local.get $b
    struct.get $rec_Point $f0
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    struct.get $rec_Point $f1
    local.get $b
    struct.get $rec_Point $f1
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    i32.const 1
  )
  (func $__pr1 (param $v i32)
    local.get $v
    call $__print_i32_raw
  )
  (func $__pr0 (param $v (ref null $rec_Point))
    global.get $__s2
    call $__print_str_raw
    global.get $__s3
    call $__print_str_raw
    global.get $__s4
    call $__print_str_raw
    local.get $v
    struct.get $rec_Point $f0
    call $__pr1
    global.get $__s5
    call $__print_str_raw
    local.get $v
    struct.get $rec_Point $f1
    call $__pr1
    global.get $__s6
    call $__print_str_raw
  )
  (func $__pr3 (param $v (ref null $str))
    local.get $v
    call $__print_quoted_raw
  )
  (func $__pr4 (param $v i32)
    local.get $v
    call $__print_bool_raw
  )
  (func $__pr5 (param $v f64)
    local.get $v
    call $__print_f64_raw
  )
  (func $__pr6 (param $v anyref)
    local.get $v
    call $__print_tagged_raw
  )
  (func $__pr2 (param $v (ref null $rec_Person))
    global.get $__s8
    call $__print_str_raw
    global.get $__s3
    call $__print_str_raw
    global.get $__s9
    call $__print_str_raw
    local.get $v
    struct.get $rec_Person $f0
    call $__pr3
    global.get $__s10
    call $__print_str_raw
    local.get $v
    struct.get $rec_Person $f1
    call $__pr1
    global.get $__s11
    call $__print_str_raw
    local.get $v
    struct.get $rec_Person $f2
    call $__pr4
    global.get $__s12
    call $__print_str_raw
    local.get $v
    struct.get $rec_Person $f3
    call $__pr5
    global.get $__s13
    call $__print_str_raw
    local.get $v
    struct.get $rec_Person $f4
    call $__pr6
    global.get $__s6
    call $__print_str_raw
  )
  (func $__print_tagged_raw (param $v anyref)
    local.get $v
    ref.test (ref null $rec_Point)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Point)
    call $__pr0
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_Person)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Person)
    call $__pr2
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
  (func $__print_f64 (param $x f64)
    local.get $x
    call $__print_f64_raw
    call $__print_nl
  )
  (func $__print_f64_raw (param $x f64)
    (local $s i32) (local $top i32)
    global.get $__heap_ptr
    local.set $top
    local.get $x
    call $__std_number_floatToString
    local.set $s
    local.get $s
    i32.const 4
    i32.add
    local.get $s
    i32.load
    call $__write_bytes
    local.get $top
    global.set $__heap_ptr
  )
  (func $__str_concat (param $a (ref null $str)) (param $b (ref null $str)) (result (ref null $str))
    (local $r (ref null $str)) (local $alen i32) (local $blen i32)
    local.get $a
    array.len
    local.set $alen
    local.get $b
    array.len
    local.set $blen
    local.get $alen
    local.get $blen
    i32.add
    array.new_default $str
    local.set $r
    local.get $r
    i32.const 0
    local.get $a
    i32.const 0
    local.get $alen
    array.copy $str $str
    local.get $r
    local.get $alen
    local.get $b
    i32.const 0
    local.get $blen
    array.copy $str $str
    local.get $r
  )
  (func $__write_err (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 2
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__assert_fail (param $where i32) (param $msg i32)
    local.get $where
    i32.const 4
    i32.add
    local.get $where
    i32.load
    call $__write_err
    i32.const 188
    i64.const 8390880602276044858
    i64.store
    i32.const 196
    i64.const 7811882119909502825
    i64.store
    i32.const 204
    i32.const 101
    i32.store8
    i32.const 205
    i32.const 100
    i32.store8
    i32.const 188
    i32.const 18
    call $__write_err
    local.get $msg
    (if
      (then
        i32.const 188
        i32.const 8250
        i32.store
        i32.const 188
        i32.const 2
        call $__write_err
        local.get $msg
        i32.const 4
        i32.add
        local.get $msg
        i32.load
        call $__write_err
      )
    )
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
  )
  (func $__panic_fail (param $msg (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    i32.const 188
    i64.const 9071397899755888
    i64.store
    i32.const 188
    i32.const 7
    call $__write_err
    local.get $msg
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
        local.get $msg
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
    call $__write_err
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
    local.get $top
    global.set $__heap_ptr
  )
  (func $__print_quoted_raw (param $s (ref null $str))
    (local $n i32) (local $i i32) (local $ch i32) (local $e i32)
    i32.const 8
    i32.const 34
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
    local.get $s
    array.len
    local.set $n
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $s
        local.get $i
        array.get_u $str
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
  (func $__print_i64_raw (param $v i64)
    local.get $v
    call $__std_number_i64ToString
    call $__print_str_raw
  )
  (func $__print_i64 (param $v i64)
    local.get $v
    call $__print_i64_raw
    call $__print_nl
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
        local.get $site
        call $__chk_fail
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
            local.get $site
            call $__chk_fail
            unreachable
          )
        )
      )
    )
    local.get $r
  )
  (func $__print_u64_raw (param $v i64)
    local.get $v
    call $__std_number_u64ToString
    call $__print_str_raw
  )
  (func $__print_u64 (param $v i64)
    local.get $v
    call $__print_u64_raw
    call $__print_nl
  )
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  (data $__d0 "integer overflow: + on i32 at main.bp:5:16")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "hi ")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "Point")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "(")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "x: ")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 ", y: ")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 ")")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "Ana")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "Person")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "name: ")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 ", age: ")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 ", tall: ")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (data $__d12 ", h: ")
  (global $__s12 (mut (ref null $str)) (ref.null $str))
  (data $__d13 ", home: ")
  (global $__s13 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 42
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 3
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 5
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 1
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 3
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 5
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 1
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 3
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 6
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 6
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 7
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 8
    array.new_data $str $__d11
    global.set $__s11
    i32.const 0
    i32.const 5
    array.new_data $str $__d12
    global.set $__s12
    i32.const 0
    i32.const 8
    array.new_data $str $__d13
    global.set $__s13
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
3
Point(x: 1, y: 2)
hi Ana
Person(name: "Ana", age: 30, tall: true, h: 1.75, home: Point(x: 1, y: 2))
2
1.75
true
true
false
```
