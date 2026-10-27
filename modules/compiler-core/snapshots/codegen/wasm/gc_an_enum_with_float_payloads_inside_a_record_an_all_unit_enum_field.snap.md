----- SOURCE CODE -- main.bp
```botopink
type Shape {
    Circle(radius: f64),
    Square(side: f64),
}

type Color { Red, Green, Blue }

type Item(shape: Shape, color: Color, label: string)

fn area(shape: Shape) -> f64 {
    return case shape {
        Circle(radius) -> radius * radius * 3.14;
        Square(side) -> side * side;
    };
}

fn warm(c: Color) -> bool {
    return case c {
        Red -> true;
        Green -> false;
        Blue -> false;
    };
}

pub fn main() -> void {
    print(area(Shape.Square(side: 2.0)));
    print(area(Shape.Circle(radius: 1.0)));
    val it = Item(shape: Shape.Square(side: 3.0), color: Color.Green, label: "x");
    print(it);
    print(warm(it.color));
    print(it.color);
    print(area(it.shape));
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
    (type $sig_0 (func (param (ref null $closure)) (result anyref)))
    (type $sig_1 (func (param (ref null $closure) anyref) (result anyref)))
    (type $sig_2 (func (param (ref null $closure) anyref anyref) (result anyref)))
    (type $sig_3 (func (param (ref null $closure) anyref anyref anyref) (result anyref)))
    (type $sig_4 (func (param (ref null $closure) anyref anyref anyref anyref) (result anyref)))
    (type $sig_5 (func (param (ref null $closure) anyref anyref anyref anyref anyref) (result anyref)))
    (type $sig_6 (func (param (ref null $closure) anyref anyref anyref anyref anyref anyref) (result anyref)))
    (type $sig_7 (func (param (ref null $closure) anyref anyref anyref anyref anyref anyref anyref) (result anyref)))
    (type $sig_8 (func (param (ref null $closure) anyref anyref anyref anyref anyref anyref anyref anyref) (result anyref)))
  )
  (rec
    (type $rec_Item (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut anyref)) (field $f1 (mut i32)) (field $f2 (mut (ref null $str))))))
    (type $brand_rec_Item (struct (field f64) (field f32) (field i64) (field i64) (field f64) (field i64) (field i32) (field i64) (field f32) (field i64) (field i32) (field f32) (field f64) (field f32) (field f32) (field f32) (field f32) (field i32) (field f64) (field f64) (field f64) (field f64) (field f64) (field i32) (field f32) (field f64) (field i64) (field f64) (field f32) (field f64) (field i32) (field f32)))
  )
  (rec
    (type $var_Shape_Circle (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut f64)))))
    (type $brand_var_Shape_Circle (struct (field i64) (field i32) (field i64) (field i32) (field f32) (field i64) (field i64) (field f64) (field i64) (field i64) (field i32) (field f64) (field i64) (field f32) (field f32) (field f64) (field i64) (field f32) (field i32) (field i64) (field f64) (field f32) (field f64) (field f32) (field i64) (field i32) (field i32) (field f32) (field f64) (field i32) (field i64) (field i32)))
  )
  (rec
    (type $var_Shape_Square (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut f64)))))
    (type $brand_var_Shape_Square (struct (field i32) (field i64) (field i32) (field i64) (field i64) (field i64) (field i64) (field f32) (field f64) (field i64) (field f64) (field i64) (field f64) (field f32) (field f64) (field i64) (field i32) (field i32) (field i64) (field i64) (field i64) (field f64) (field i64) (field i64) (field f32) (field f64) (field i32) (field f32) (field f32) (field f64) (field f64) (field f32)))
  )
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@number" "wat:number.i64ToString" (func $__abi___std_number_i64ToString (param i64) (result arrayref)))
  (import "std@number" "wat:number.u64ToString" (func $__abi___std_number_u64ToString (param i64) (result arrayref)))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $area (param $shape anyref) (result f64)
    (local $radius f64)
    (local $side f64)
    (local $__case_0 anyref)
    local.get $shape
    local.set $__case_0
    local.get $__case_0
    ref.test (ref null $var_Shape_Circle)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result f64)
      (then
    local.get $__case_0
    ref.cast (ref null $var_Shape_Circle)
    struct.get $var_Shape_Circle $f0
    local.set $radius
    local.get $radius
    local.get $radius
    f64.mul
    f64.const 3.14
    f64.mul
      )
      (else
    local.get $__case_0
    ref.test (ref null $var_Shape_Square)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result f64)
      (then
    local.get $__case_0
    ref.cast (ref null $var_Shape_Square)
    struct.get $var_Shape_Square $f0
    local.set $side
    local.get $side
    local.get $side
    f64.mul
      )
      (else
    f64.const 0
      )
    )
      )
    )
    return
  )
  (func $warm (param $c i32) (result i32)
    (local $__case_0 i32)
    local.get $c
    local.set $__case_0
    local.get $__case_0
    i32.const 0 ;; Red
    i32.eq
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $__case_0
    i32.const 1 ;; Green
    i32.eq
    (if (result i32)
      (then
    i32.const 0
      )
      (else
    local.get $__case_0
    i32.const 2 ;; Blue
    i32.eq
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
  (func $main (export "main")
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $it (ref null $rec_Item))
    f64.const 2.0
    call $__new_35
    call $area
    call $__print_f64
    f64.const 1.0
    call $__new_33
    call $area
    call $__print_f64
    f64.const 3.0
    call $__new_35
    i32.const 1 ;; Color.Green
    global.get $__s0
    call $__new_31
    local.set $it
    local.get $it
    call $__pr0
    call $__print_nl
    local.get $it
    struct.get $rec_Item $f1
    call $warm
    call $__print_bool
    local.get $it
    struct.get $rec_Item $f1
    call $__pr2
    call $__print_nl
    local.get $it
    struct.get $rec_Item $f0
    call $area
    call $__print_f64
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__pr1 (param $v anyref)
    local.get $v
    call $__print_tagged_raw
  )
  (func $__pr2 (param $v i32)
    local.get $v
    i32.const 0
    i32.eq
    (if
      (then
    global.get $__s5
    call $__print_str_raw
    return
      )
    )
    local.get $v
    i32.const 1
    i32.eq
    (if
      (then
    global.get $__s6
    call $__print_str_raw
    return
      )
    )
    local.get $v
    i32.const 2
    i32.eq
    (if
      (then
    global.get $__s7
    call $__print_str_raw
    return
      )
    )
  )
  (func $__pr3 (param $v (ref null $str))
    local.get $v
    call $__print_quoted_raw
  )
  (func $__pr0 (param $v (ref null $rec_Item))
    global.get $__s1
    call $__print_str_raw
    global.get $__s2
    call $__print_str_raw
    global.get $__s3
    call $__print_str_raw
    local.get $v
    struct.get $rec_Item $f0
    call $__pr1
    global.get $__s4
    call $__print_str_raw
    local.get $v
    struct.get $rec_Item $f1
    call $__pr2
    global.get $__s8
    call $__print_str_raw
    local.get $v
    struct.get $rec_Item $f2
    call $__pr3
    global.get $__s9
    call $__print_str_raw
  )
  (func $__pr5 (param $v f64)
    local.get $v
    call $__print_f64_raw
  )
  (func $__pr4 (param $v (ref null $var_Shape_Circle))
    global.get $__s10
    call $__print_str_raw
    global.get $__s2
    call $__print_str_raw
    global.get $__s11
    call $__print_str_raw
    local.get $v
    struct.get $var_Shape_Circle $f0
    call $__pr5
    global.get $__s9
    call $__print_str_raw
  )
  (func $__pr6 (param $v (ref null $var_Shape_Square))
    global.get $__s12
    call $__print_str_raw
    global.get $__s2
    call $__print_str_raw
    global.get $__s13
    call $__print_str_raw
    local.get $v
    struct.get $var_Shape_Square $f0
    call $__pr5
    global.get $__s9
    call $__print_str_raw
  )
  (func $__print_tagged_raw (param $v anyref)
    local.get $v
    ref.test (ref null $var_Shape_Circle)
    (if
      (then
    local.get $v
    ref.cast (ref null $var_Shape_Circle)
    call $__pr4
    return
      )
    )
    local.get $v
    ref.test (ref null $var_Shape_Square)
    (if
      (then
    local.get $v
    ref.cast (ref null $var_Shape_Square)
    call $__pr6
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_Item)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Item)
    call $__pr0
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
  (data $__d0 "x")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "Item")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "(")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "shape: ")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 ", color: ")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "Color.Red")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "Color.Green")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "Color.Blue")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 ", label: ")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 ")")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "Shape.Circle")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 "radius: ")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (data $__d12 "Shape.Square")
  (global $__s12 (mut (ref null $str)) (ref.null $str))
  (data $__d13 "side: ")
  (global $__s13 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 1
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 4
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 1
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 7
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 9
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 9
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 11
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 10
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 9
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 1
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 12
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 8
    array.new_data $str $__d11
    global.set $__s11
    i32.const 0
    i32.const 12
    array.new_data $str $__d12
    global.set $__s12
    i32.const 0
    i32.const 6
    array.new_data $str $__d13
    global.set $__s13
  )
  (global $__ti_35 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (func $__new_35 (param $f0 f64) (result (ref null $var_Shape_Square))
    global.get $__ti_35
    local.get $f0
    struct.new $var_Shape_Square
  )
  (global $__ti_33 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (func $__new_33 (param $f0 f64) (result (ref null $var_Shape_Circle))
    global.get $__ti_33
    local.get $f0
    struct.new $var_Shape_Circle
  )
  (global $__ti_31 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (func $__new_31 (param $f0 anyref) (param $f1 i32) (param $f2 (ref null $str)) (result (ref null $rec_Item))
    global.get $__ti_31
    local.get $f0
    local.get $f1
    local.get $f2
    struct.new $rec_Item
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
4.0
3.14
Item(shape: Shape.Square(side: 3.0), color: Color.Green, label: "x")
false
Color.Green
9.0
```
