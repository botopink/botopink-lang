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

fn main() -> void {
    val u: unknown = Vec(name: "Ana", age: 30);
    print(u is Vec);
    print(u is Person);
    val s: unknown = Shape.Circle(radius: 4);
    print(s is Shape);
    val d: unknown = Shape.Dot;
    print(d is Shape);
    print(nameOf(Person(name: "Ana", age: 30)));
    print(nameOf(Vec(name: "Ana", age: 30)));
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
    (type $box_big (struct (field $v (ref null $str))))
    (type $closure (sub (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $exn (struct (field $msg (ref null $str)) (field $print i32)))
    (type $task (struct (field $state (mut i32)) (field $waiters (mut (ref null $waiter))) (field $value (mut anyref)) (field $frame (mut structref)) (field $kind i32) (field $next (mut (ref null $task))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $waiter (struct (field $next (mut (ref null $waiter))) (field $kind i32) (field $target (ref null $task)) (field $slot i32)))
    (type $hostn (struct (field $next (mut (ref null $hostn))) (field $h i32) (field $t (ref null $task))))
    (type $gen (struct (field $state (mut i32)) (field $kind i32) (field $frame (mut structref)) (field $value (mut anyref)) (field $src (mut (ref null $gen))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $cell (struct (field $filled (mut i32)) (field $value (mut anyref))))
    (type $__decl (sub (struct (field $ti (ref null $__tinfo)))))
    (type $__tinfo (struct (field $name (ref null $str)) (field $print funcref) (field $eq funcref) (field $display funcref) (field $kind i32)))
    (type $__print_sig (func (param anyref)))
    (type $__eq_sig (func (param anyref anyref) (result i32)))
  )
  (rec
    (type $rec_Person (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut (ref null $str))) (field $f1 (mut i32)))))
    (type $brand_rec_Person (struct (field f64) (field i64) (field f64) (field f64) (field i64) (field i32) (field f32) (field f32) (field i64) (field f32) (field f32) (field f32) (field i64) (field i64) (field i32) (field i32) (field f64) (field i32) (field f32) (field f64) (field i64) (field f64) (field i32) (field i32) (field f32) (field f32) (field i64) (field i32) (field i64) (field i64) (field f32) (field i64)))
  )
  (rec
    (type $var_Shape_Circle (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut i32)))))
    (type $brand_var_Shape_Circle (struct (field i64) (field i32) (field i64) (field i32) (field f32) (field i64) (field i64) (field f64) (field i64) (field i64) (field i32) (field f64) (field i64) (field f32) (field f32) (field f64) (field i64) (field f32) (field i32) (field i64) (field f64) (field f32) (field f64) (field f32) (field i64) (field i32) (field i32) (field f32) (field f64) (field i32) (field i64) (field i32)))
  )
  (rec
    (type $var_Shape_Dot (sub final $__decl (struct (field $ti (ref null $__tinfo)))))
    (type $brand_var_Shape_Dot (struct (field i64) (field i64) (field i32) (field f64) (field i32) (field f32) (field f32) (field i64) (field i32) (field i32) (field f32) (field i64) (field f64) (field f64) (field i32) (field f32) (field i64) (field i64) (field i64) (field i32) (field i64) (field i32) (field i32) (field i64) (field f32) (field f64) (field f64) (field f32) (field f32) (field i32) (field f64) (field f32)))
  )
  (rec
    (type $rec_Vec (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut (ref null $str))) (field $f1 (mut i32)))))
    (type $brand_rec_Vec (struct (field i64) (field i64) (field i32) (field f64) (field i32) (field f64) (field i32) (field f32) (field f64) (field f64) (field i64) (field i64) (field f64) (field f64) (field i32) (field f64) (field i64) (field f64) (field i64) (field f32) (field f32) (field i32) (field f32) (field i64) (field i64) (field f64) (field f64) (field i64) (field i64) (field i64) (field i32) (field i32)))
  )
  (import "std@__rt" "__ti_register" (func $__ti_register (param structref)))
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@number" "wat:number.i64ToString" (func $__abi___std_number_i64ToString (param i64) (result arrayref)))
  (import "std@number" "wat:number.u64ToString" (func $__abi___std_number_u64ToString (param i64) (result arrayref)))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $nameOf (param $v anyref) (result (ref null $str))
    (local $Person i32)
    (local $Vec i32)
    (local $__case_0 anyref)
    (local $Person__0 anyref)
    (local $Vec__1 anyref)
    local.get $v
    local.set $__case_0
    local.get $__case_0
    ref.test (ref null $rec_Person)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    local.set $Person__0
    global.get $__s0
      )
      (else
    local.get $__case_0
    ref.test (ref null $rec_Vec)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    local.set $Vec__1
    global.get $__s1
      )
      (else
    ref.null $str
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
    (local $u anyref)
    (local $s anyref)
    (local $d anyref)
    (local $__gc0 anyref)
    (local $__gc1 anyref)
    (local $__gc2 anyref)
    (local $__gc3 anyref)
    global.get $__s2
    i32.const 30
    call $__new_28
    local.set $u
    local.get $u
    local.set $__gc0
    local.get $__gc0
    ref.test (ref null $rec_Vec)
    local.get $__gc0
    ref.is_null
    i32.eqz
    i32.and
    call $__print_bool
    local.get $u
    local.set $__gc1
    local.get $__gc1
    ref.test (ref null $rec_Person)
    local.get $__gc1
    ref.is_null
    i32.eqz
    i32.and
    call $__print_bool
    i32.const 4
    call $__new_24
    local.set $s
    local.get $s
    local.set $__gc2
    local.get $__gc2
    ref.test (ref null $var_Shape_Dot)
    local.get $__gc2
    ref.test (ref null $var_Shape_Circle)
    i32.or
    local.get $__gc2
    ref.is_null
    i32.eqz
    i32.and
    call $__print_bool
    call $__new_26
    local.set $d
    local.get $d
    local.set $__gc3
    local.get $__gc3
    ref.test (ref null $var_Shape_Dot)
    local.get $__gc3
    ref.test (ref null $var_Shape_Circle)
    i32.or
    local.get $__gc3
    ref.is_null
    i32.eqz
    i32.and
    call $__print_bool
    global.get $__s2
    i32.const 30
    call $__new_22
    call $nameOf
    call $__print_str
    global.get $__s2
    i32.const 30
    call $__new_28
    call $nameOf
    call $__print_str
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__eq_Person (param $a (ref null $rec_Person)) (param $b (ref null $rec_Person)) (result i32)
    local.get $a
    struct.get $rec_Person $f0
    local.get $b
    struct.get $rec_Person $f0
    call $__str_eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    struct.get $rec_Person $f1
    local.get $b
    struct.get $rec_Person $f1
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    i32.const 1
  )
  (func $__eq_Vec (param $a (ref null $rec_Vec)) (param $b (ref null $rec_Vec)) (result i32)
    local.get $a
    struct.get $rec_Vec $f0
    local.get $b
    struct.get $rec_Vec $f0
    call $__str_eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    struct.get $rec_Vec $f1
    local.get $b
    struct.get $rec_Vec $f1
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    i32.const 1
  )
  (func $__eq_Shape (param $a anyref) (param $b anyref) (result i32)
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
    i32.const 0
  )
  (func $__pr1 (param $v (ref null $str))
    local.get $v
    call $__print_quoted_raw
  )
  (func $__pr2 (param $v i32)
    local.get $v
    call $__print_i32_raw
  )
  (func $__pr0 (param $v (ref null $rec_Person))
    global.get $__s3
    call $__print_str_raw
    global.get $__s4
    call $__print_str_raw
    global.get $__s5
    call $__print_str_raw
    local.get $v
    struct.get $rec_Person $f0
    call $__pr1
    global.get $__s6
    call $__print_str_raw
    local.get $v
    struct.get $rec_Person $f1
    call $__pr2
    global.get $__s7
    call $__print_str_raw
  )
  (func $__tip1 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Person)
    call $__pr0
  )
  (func $__tie1 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Person)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Person)
    local.get $b
    ref.cast (ref null $rec_Person)
    call $__eq_Person
  )
  (func $__pr3 (param $v (ref null $rec_Vec))
    global.get $__s9
    call $__print_str_raw
    global.get $__s4
    call $__print_str_raw
    global.get $__s5
    call $__print_str_raw
    local.get $v
    struct.get $rec_Vec $f0
    call $__pr1
    global.get $__s6
    call $__print_str_raw
    local.get $v
    struct.get $rec_Vec $f1
    call $__pr2
    global.get $__s7
    call $__print_str_raw
  )
  (func $__tip2 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Vec)
    call $__pr3
  )
  (func $__tie2 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Vec)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Vec)
    local.get $b
    ref.cast (ref null $rec_Vec)
    call $__eq_Vec
  )
  (func $__pr4 (param $v (ref null $var_Shape_Circle))
    global.get $__s11
    call $__print_str_raw
    global.get $__s4
    call $__print_str_raw
    global.get $__s12
    call $__print_str_raw
    local.get $v
    struct.get $var_Shape_Circle $f0
    call $__pr2
    global.get $__s7
    call $__print_str_raw
  )
  (func $__tip3 (param $v anyref)
    local.get $v
    ref.cast (ref null $var_Shape_Circle)
    call $__pr4
  )
  (func $__tie3 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $var_Shape_Circle)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__eq_Shape
  )
  (func $__pr5 (param $v (ref null $var_Shape_Dot))
    global.get $__s14
    call $__print_str_raw
  )
  (func $__tip4 (param $v anyref)
    local.get $v
    ref.cast (ref null $var_Shape_Dot)
    call $__pr5
  )
  (func $__tie4 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $var_Shape_Dot)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__eq_Shape
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
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
  (func $__str_eq (param $a (ref null $str)) (param $b (ref null $str)) (result i32)
    (local $i i32) (local $n i32) (local $an i32) (local $bn i32)
    local.get $a
    ref.is_null
    local.set $an
    local.get $b
    ref.is_null
    local.set $bn
    local.get $an
    local.get $bn
    i32.or
    (if
      (then
        local.get $an
        local.get $bn
        i32.and
        return
      )
    )
    local.get $a
    array.len
    local.set $n
    local.get $n
    local.get $b
    array.len
    i32.ne
    (if
      (then
        i32.const 0
        return
      )
    )
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $a
        local.get $i
        array.get_u $str
        local.get $b
        local.get $i
        array.get_u $str
        i32.ne
        (if
          (then
            i32.const 0
            return
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    i32.const 1
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
  (func $__std_number_i64ToString (param $p0 i64) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_i64ToString
    ref.cast (ref null $str)
  )
  (func $__std_number_u64ToString (param $p0 i64) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_u64ToString
    ref.cast (ref null $str)
  )
  (data $__d0 "person")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "vec")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "Ana")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "Person")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "(")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "name: ")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 ", age: ")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 ")")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "test@main.Person")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "Vec")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "test@main.Vec")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 "Shape.Circle")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (data $__d12 "radius: ")
  (global $__s12 (mut (ref null $str)) (ref.null $str))
  (data $__d13 "test@main.Shape.Circle")
  (global $__s13 (mut (ref null $str)) (ref.null $str))
  (data $__d14 "Shape.Dot")
  (global $__s14 (mut (ref null $str)) (ref.null $str))
  (data $__d15 "test@main.Shape.Dot")
  (global $__s15 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 6
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 3
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 3
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 6
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 1
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 6
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 7
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 1
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 16
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 3
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 13
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 12
    array.new_data $str $__d11
    global.set $__s11
    i32.const 0
    i32.const 8
    array.new_data $str $__d12
    global.set $__s12
    i32.const 0
    i32.const 22
    array.new_data $str $__d13
    global.set $__s13
    i32.const 0
    i32.const 9
    array.new_data $str $__d14
    global.set $__s14
    i32.const 0
    i32.const 19
    array.new_data $str $__d15
    global.set $__s15
    call $__init_types
  )
  (func $__new_28 (param $f0 (ref null $str)) (param $f1 i32) (result (ref null $rec_Vec))
    global.get $__ti_28
    local.get $f0
    local.get $f1
    struct.new $rec_Vec
  )
  (func $__new_24 (param $f0 i32) (result (ref null $var_Shape_Circle))
    global.get $__ti_24
    local.get $f0
    struct.new $var_Shape_Circle
  )
  (func $__new_26 (result (ref null $var_Shape_Dot))
    global.get $__ti_26
    struct.new $var_Shape_Dot
  )
  (func $__new_22 (param $f0 (ref null $str)) (param $f1 i32) (result (ref null $rec_Person))
    global.get $__ti_22
    local.get $f0
    local.get $f1
    struct.new $rec_Person
  )
  (global $__ti_28 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_24 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_26 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_22 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (elem declare func $__tip1 $__tie1 $__tip2 $__tie2 $__tip3 $__tie3 $__tip4 $__tie4)
  (func $__init_types
    global.get $__s8
    ref.func $__tip1
    ref.func $__tie1
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_22
    global.get $__ti_22
    call $__ti_register
    global.get $__s10
    ref.func $__tip2
    ref.func $__tie2
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_28
    global.get $__ti_28
    call $__ti_register
    global.get $__s13
    ref.func $__tip3
    ref.func $__tie3
    ref.null func
    i32.const 1
    struct.new $__tinfo
    global.set $__ti_24
    global.get $__ti_24
    call $__ti_register
    global.get $__s15
    ref.func $__tip4
    ref.func $__tie4
    ref.null func
    i32.const 1
    struct.new $__tinfo
    global.set $__ti_26
    global.get $__ti_26
    call $__ti_register
  )
  (@custom "botopink.needs" "gc\0a")
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
