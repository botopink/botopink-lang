----- SOURCE CODE -- main.bp
```botopink
import {io.terminal.print} from "std";

type Shape { Circle(r: i32), Square(side: i32) }

type Person(name: string, age: i32)

fn parse(s: string) -> Result<i32, string> {
    if (s == "") throw "empty input";
    return s.length;
}

fn radius(s: Shape) -> i32 {
    val assert Circle(r) = s catch Shape.Circle(r: 0 - 1);
    return r;
}

fn describe(p: Person) -> string {
    val assert Person(n, a) = p;
    return n + "/" + a.toString();
}

fn size(s: string) -> i32 {
    val assert Ok(n) = parse(s);
    return n;
}

fn reason(s: string) -> string {
    val assert Error(message) = parse(s);
    return message;
}

fn older(p: Person) -> i32 {
    val assert Person(n, a) = p catch Person(name: "none", age: 0);
    return a + n.length;
}

pub fn main() -> void {
    print(radius(Shape.Circle(r: 3)));
    print(radius(Shape.Square(side: 2)));
    print(describe(Person(name: "ana", age: 30)));
    print(size("four"));
    print(reason(""));
    print(older(Person(name: "bo", age: 41)));
}
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
    (type $rec_Person (struct (field $f0 (mut (ref null $str))) (field $f1 (mut i32))))
    (type $brand_rec_Person (struct (field f64) (field i64) (field f64) (field f64) (field i64) (field i32) (field f32) (field f32) (field i64) (field f32) (field f32) (field f32) (field i64) (field i64) (field i32) (field i32) (field f64) (field i32) (field f32) (field f64) (field i64) (field f64) (field i32) (field i32) (field f32) (field f32) (field i64) (field i32) (field i64) (field i64) (field f32) (field i64)))
  )
  (rec
    (type $var_Shape_Circle (struct (field $f0 (mut i32))))
    (type $brand_var_Shape_Circle (struct (field i64) (field i32) (field i64) (field i32) (field f32) (field i64) (field i64) (field f64) (field i64) (field i64) (field i32) (field f64) (field i64) (field f32) (field f32) (field f64) (field i64) (field f32) (field i32) (field i64) (field f64) (field f32) (field f64) (field f32) (field i64) (field i32) (field i32) (field f32) (field f64) (field i32) (field i64) (field i32)))
  )
  (rec
    (type $var_Shape_Square (struct (field $f0 (mut i32))))
    (type $brand_var_Shape_Square (struct (field i32) (field i64) (field i32) (field i64) (field i64) (field i64) (field i64) (field f32) (field f64) (field i64) (field f64) (field i64) (field f64) (field f32) (field f64) (field i64) (field i32) (field i32) (field i64) (field i64) (field i64) (field f64) (field i64) (field i64) (field f32) (field f64) (field i32) (field f32) (field f32) (field f64) (field f64) (field f32)))
  )
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $parse (param $s (ref null $str)) (result (ref null $result))
    local.get $s
    global.get $__s0
    call $__str_eq
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s1
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    local.get $s
    call $__std_text_length
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $radius (param $s anyref) (result i32)
    (local $__assert_0 anyref)
    (local $r i32)
    local.get $s
    local.set $__assert_0
    local.get $__assert_0
    ref.test (ref null $var_Shape_Circle)
    local.get $__assert_0
    ref.is_null
    i32.eqz
    i32.and
    i32.eqz
    (if
      (then
    i32.const 0
    i32.const 1
    global.get $__s2
    call $__i32_sub_chk
    struct.new $var_Shape_Circle
    local.set $__assert_0
      )
    )
    local.get $__assert_0
    ref.cast (ref null $var_Shape_Circle)
    struct.get $var_Shape_Circle $f0
    local.set $r
    local.get $r
    return
  )
  (func $describe (param $p (ref null $rec_Person)) (result (ref null $str))
    (local $__assert_0 (ref null $rec_Person))
    (local $n (ref null $str))
    (local $a i32)
    local.get $p
    local.set $__assert_0
    local.get $__assert_0
    ref.test (ref null $rec_Person)
    local.get $__assert_0
    ref.is_null
    i32.eqz
    i32.and
    i32.eqz
    (if
      (then
    global.get $__s3
    call $__panic_fail
    unreachable
      )
    )
    local.get $__assert_0
    struct.get $rec_Person $f0
    local.set $n
    local.get $__assert_0
    struct.get $rec_Person $f1
    local.set $a
    local.get $n
    global.get $__s4
    call $__str_concat
    local.get $a
    call $__std_number_i32ToString
    call $__str_concat
    return
  )
  (func $size (param $s (ref null $str)) (result i32)
    (local $__assert_0 (ref null $result))
    (local $n i32)
    local.get $s
    call $parse
    local.set $__assert_0
    local.get $__assert_0
    struct.get $result $tag
    i32.eqz
    i32.eqz
    (if
      (then
    global.get $__s3
    call $__panic_fail
    unreachable
      )
    )
    local.get $__assert_0
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $n
    local.get $n
    return
  )
  (func $reason (param $s (ref null $str)) (result (ref null $str))
    (local $__assert_0 (ref null $result))
    (local $message (ref null $str))
    local.get $s
    call $parse
    local.set $__assert_0
    local.get $__assert_0
    struct.get $result $tag
    i32.eqz
    (if
      (then
    global.get $__s3
    call $__panic_fail
    unreachable
      )
    )
    local.get $__assert_0
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $message
    local.get $message
    return
  )
  (func $older (param $p (ref null $rec_Person)) (result i32)
    (local $__assert_0 (ref null $rec_Person))
    (local $n (ref null $str))
    (local $a i32)
    local.get $p
    local.set $__assert_0
    local.get $__assert_0
    ref.test (ref null $rec_Person)
    local.get $__assert_0
    ref.is_null
    i32.eqz
    i32.and
    i32.eqz
    (if
      (then
    global.get $__s5
    i32.const 0
    struct.new $rec_Person
    local.set $__assert_0
      )
    )
    local.get $__assert_0
    struct.get $rec_Person $f0
    local.set $n
    local.get $__assert_0
    struct.get $rec_Person $f1
    local.set $a
    local.get $a
    local.get $n
    call $__std_text_length
    global.get $__s6
    call $__i32_add_chk
    return
  )
  (func $main (export "main")
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    i32.const 3
    struct.new $var_Shape_Circle
    call $radius
    call $__print_i32
    i32.const 2
    struct.new $var_Shape_Square
    call $radius
    call $__print_i32
    global.get $__s7
    i32.const 30
    struct.new $rec_Person
    call $describe
    call $__print_str
    global.get $__s8
    call $size
    call $__print_i32
    global.get $__s0
    call $reason
    call $__print_str
    global.get $__s9
    i32.const 41
    struct.new $rec_Person
    call $older
    call $__print_i32
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
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
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  ;; std-wasm's .wat leaves (front 164 s3)
  (func $__std_text_length (param $s (ref null $str)) (result i32)
    (local $i i32)
    (local $len i32)
    (local $n i32)
    local.get $s
    array.len
    local.set $len
    (block $done
      (loop $next
        local.get $i
        local.get $len
        i32.ge_u
        br_if $done
        local.get $s
        local.get $i
        array.get_u $str
        i32.const 0xC0
        i32.and
        i32.const 0x80
        i32.ne
        local.get $n
        i32.add
        local.set $n
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $next
      )
    )
    local.get $n
  )
  (func $__std_number_i32ToString (param $v i32) (result (ref null $str))
    local.get $v
    i64.extend_i32_s
    call $__std_number_i64ToString
  )
  (func $__std_number_decimal (param $mag i64) (param $neg i32) (result (ref null $str))
    (local $n i32)
    (local $i i32)
    (local $t i64)
    (local $out (ref null $str))
    local.get $mag
    local.set $t
    (block $counted
      (loop $count
        local.get $n
        i32.const 1
        i32.add
        local.set $n
        local.get $t
        i64.const 10
        i64.div_u
        local.tee $t
        i64.eqz
        br_if $counted
        br $count
      )
    )
    local.get $n
    local.get $neg
    i32.add
    local.tee $i
    array.new_default $str
    local.set $out
    local.get $mag
    local.set $t
    (block $filled
      (loop $fill
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        local.get $out
        local.get $i
        local.get $t
        i64.const 10
        i64.rem_u
        i32.wrap_i64
        i32.const 48
        i32.add
        array.set $str
        local.get $t
        i64.const 10
        i64.div_u
        local.tee $t
        i64.eqz
        br_if $filled
        br $fill
      )
    )
    local.get $neg
    (if
      (then
        local.get $out
        i32.const 0
        i32.const 45
        array.set $str
      )
    )
    local.get $out
  )
  (func $__std_number_i64ToString (param $v i64) (result (ref null $str))
    local.get $v
    i64.const 0
    i64.lt_s
    (if (result (ref null $str))
      (then
        i64.const 0
        local.get $v
        i64.sub
        i32.const 1
        call $__std_number_decimal
      )
      (else
        local.get $v
        i32.const 0
        call $__std_number_decimal
      )
    )
  )
  (data $__d0 "")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "empty input")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "integer overflow: - on i32 at main.bp:13:54")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "assert pattern did not match")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "/")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "none")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "integer overflow: + on i32 at main.bp:34:14")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "ana")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "four")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "bo")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 0
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 11
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 43
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 28
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 1
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 4
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 43
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 3
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 4
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 2
    array.new_data $str $__d9
    global.set $__s9
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
3
-1
ana/30
4
empty input
43
```
