----- SOURCE CODE -- main.bp
```botopink
import {io.terminal.print} from "std";

type Field(name: string)

type Form(fields: ?Field[], tags: string[], range: #(i32, i32))

fn make(k: i32) -> ?Form {
    if (k == 0) return null;
    return Form(fields: [Field(name: "email")], tags: ["a", "b"], range: #(1, 2));
}

pub fn main() -> void {
    val f = make(1);
    val tags: string[] = f?.tags ?? [];
    print(tags.join(","));
    val none: string[] = make(0)?.tags ?? [];
    print(none.length);
    val r = f?.range ?? #(0, 0);
    print(r);
    print(f?.fields?.[0]?.name ?? "none");
    print(make(0)?.fields?.[0]?.name ?? "none");
    val empty: ?Form = Form(fields: null, tags: [], range: #(3, 4));
    print(empty?.fields?.[0]?.name ?? "none");
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
    (type $rec_Field (struct (field $f0 (mut (ref null $str)))))
    (type $brand_rec_Field (struct (field f64) (field i32) (field f32) (field i64) (field i32) (field i64) (field f64) (field i32) (field f64) (field i32) (field f64) (field f32) (field f64) (field i32) (field f32) (field f32) (field f64) (field i64) (field f64) (field f32) (field i32) (field f64) (field i64) (field f64) (field f32) (field f32) (field f64) (field i32) (field i64) (field f32) (field f32) (field f32)))
  )
  (rec
    (type $rec_Form (struct (field $f0 (mut (ref null $arr_any))) (field $f1 (mut (ref null $arr_any))) (field $f2 (mut (ref null $arr_any)))))
    (type $brand_rec_Form (struct (field f64) (field i32) (field f32) (field i32) (field i32) (field f64) (field f32) (field f32) (field f64) (field f32) (field f64) (field i32) (field f32) (field f32) (field f64) (field f32) (field i32) (field i32) (field i64) (field f64) (field f32) (field f32) (field i32) (field f64) (field f64) (field f32) (field f32) (field i64) (field i64) (field f64) (field f32) (field f32)))
  )
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $make (param $k i32) (result (ref null $rec_Form))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    local.get $k
    i32.const 0
    i32.eq
    (if (result (ref null $rec_Form))
      (then
    ref.null $rec_Form
    return
      )
      (else
        ref.null $rec_Form
      )
    )
    drop
    global.get $__s0
    struct.new $rec_Field
    array.new_fixed $arr_any 1
    global.get $__s1
    global.get $__s2
    array.new_fixed $arr_any 2
    i32.const 1
    struct.new $box_i32
    i32.const 2
    struct.new $box_i32
    array.new_fixed $tuple 2
    struct.new $rec_Form
    return
  )
  (func $main (export "main")
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
    (local $__mem14 i32)
    (local $f (ref null $rec_Form))
    (local $tags (ref null $arr_any))
    (local $__bp_nullish i32)
    (local $none (ref null $arr_any))
    (local $r (ref null $arr_any))
    (local $empty (ref null $rec_Form))
    (local $__opt0 (ref null $arr_any))
    (local $__gc0 (ref null $rec_Form))
    (local $__bp_nullish__0 (ref null $arr_any))
    (local $__opt1 (ref null $arr_any))
    (local $__gc1 (ref null $rec_Form))
    (local $__bp_nullish__1 (ref null $arr_any))
    (local $__opt2 (ref null $arr_any))
    (local $__gc2 (ref null $rec_Form))
    (local $__bp_nullish__2 (ref null $arr_any))
    (local $__opt3 (ref null $str))
    (local $__gc3 (ref null $rec_Field))
    (local $__opt4 (ref null $arr_any))
    (local $__gc4 (ref null $rec_Form))
    (local $__bp_opt_20_20 (ref null $arr_any))
    (local $__bp_nullish__3 (ref null $str))
    (local $__opt5 (ref null $str))
    (local $__gc5 (ref null $rec_Field))
    (local $__opt6 (ref null $arr_any))
    (local $__gc6 (ref null $rec_Form))
    (local $__bp_opt_21_26 (ref null $arr_any))
    (local $__bp_nullish__4 (ref null $str))
    (local $__opt7 (ref null $str))
    (local $__gc7 (ref null $rec_Field))
    (local $__opt8 (ref null $arr_any))
    (local $__gc8 (ref null $rec_Form))
    (local $__bp_opt_23_24 (ref null $arr_any))
    (local $__bp_nullish__5 (ref null $str))
    i32.const 1
    call $make
    local.set $f
    local.get $f
    local.tee $__gc0
    ref.is_null
    (if (result (ref null $arr_any))
      (then
    ref.null $arr_any
      )
      (else
    local.get $__gc0
    struct.get $rec_Form $f1
      )
    )
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $arr_any))
      (then
    local.get $__opt0
    local.set $__bp_nullish__0
    local.get $__bp_nullish__0
      )
      (else
    array.new_fixed $arr_any 0
      )
    )
    local.set $tags
    local.get $tags
    global.get $__s3
    call $__arr_join_any
    call $__print_str
    i32.const 0
    call $make
    local.tee $__gc1
    ref.is_null
    (if (result (ref null $arr_any))
      (then
    ref.null $arr_any
      )
      (else
    local.get $__gc1
    struct.get $rec_Form $f1
      )
    )
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result (ref null $arr_any))
      (then
    local.get $__opt1
    local.set $__bp_nullish__1
    local.get $__bp_nullish__1
      )
      (else
    array.new_fixed $arr_any 0
      )
    )
    local.set $none
    local.get $none
    array.len
    call $__print_i32
    local.get $f
    local.tee $__gc2
    ref.is_null
    (if (result (ref null $arr_any))
      (then
    ref.null $arr_any
      )
      (else
    local.get $__gc2
    struct.get $rec_Form $f2
      )
    )
    local.tee $__opt2
    ref.is_null
    i32.eqz
    (if (result (ref null $arr_any))
      (then
    local.get $__opt2
    local.set $__bp_nullish__2
    local.get $__bp_nullish__2
      )
      (else
    i32.const 0
    struct.new $box_i32
    i32.const 0
    struct.new $box_i32
    array.new_fixed $tuple 2
      )
    )
    local.set $r
    local.get $r
    call $__pr0
    call $__print_nl
    local.get $f
    local.tee $__gc4
    ref.is_null
    (if (result (ref null $arr_any))
      (then
    ref.null $arr_any
      )
      (else
    local.get $__gc4
    struct.get $rec_Form $f0
      )
    )
    local.tee $__opt4
    ref.is_null
    i32.eqz
    (if (result anyref)
      (then
    local.get $__opt4
    local.set $__bp_opt_20_20
    local.get $__bp_opt_20_20
    i32.const 0
    call $__arr_at_opt_any
    ref.cast (ref null $rec_Field)
      )
      (else
    ref.null any
      )
    )
    ref.cast (ref null $rec_Field)
    local.tee $__gc3
    ref.is_null
    (if (result (ref null $str))
      (then
    ref.null $str
      )
      (else
    local.get $__gc3
    struct.get $rec_Field $f0
      )
    )
    local.tee $__opt3
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt3
    local.set $__bp_nullish__3
    local.get $__bp_nullish__3
      )
      (else
    global.get $__s7
      )
    )
    call $__print_str
    i32.const 0
    call $make
    local.tee $__gc6
    ref.is_null
    (if (result (ref null $arr_any))
      (then
    ref.null $arr_any
      )
      (else
    local.get $__gc6
    struct.get $rec_Form $f0
      )
    )
    local.tee $__opt6
    ref.is_null
    i32.eqz
    (if (result anyref)
      (then
    local.get $__opt6
    local.set $__bp_opt_21_26
    local.get $__bp_opt_21_26
    i32.const 0
    call $__arr_at_opt_any
    ref.cast (ref null $rec_Field)
      )
      (else
    ref.null any
      )
    )
    ref.cast (ref null $rec_Field)
    local.tee $__gc5
    ref.is_null
    (if (result (ref null $str))
      (then
    ref.null $str
      )
      (else
    local.get $__gc5
    struct.get $rec_Field $f0
      )
    )
    local.tee $__opt5
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt5
    local.set $__bp_nullish__4
    local.get $__bp_nullish__4
      )
      (else
    global.get $__s7
      )
    )
    call $__print_str
    ref.null $arr_any
    array.new_fixed $arr_any 0
    i32.const 3
    struct.new $box_i32
    i32.const 4
    struct.new $box_i32
    array.new_fixed $tuple 2
    struct.new $rec_Form
    local.set $empty
    local.get $empty
    local.tee $__gc8
    ref.is_null
    (if (result (ref null $arr_any))
      (then
    ref.null $arr_any
      )
      (else
    local.get $__gc8
    struct.get $rec_Form $f0
      )
    )
    local.tee $__opt8
    ref.is_null
    i32.eqz
    (if (result anyref)
      (then
    local.get $__opt8
    local.set $__bp_opt_23_24
    local.get $__bp_opt_23_24
    i32.const 0
    call $__arr_at_opt_any
    ref.cast (ref null $rec_Field)
      )
      (else
    ref.null any
      )
    )
    ref.cast (ref null $rec_Field)
    local.tee $__gc7
    ref.is_null
    (if (result (ref null $str))
      (then
    ref.null $str
      )
      (else
    local.get $__gc7
    struct.get $rec_Field $f0
      )
    )
    local.tee $__opt7
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt7
    local.set $__bp_nullish__5
    local.get $__bp_nullish__5
      )
      (else
    global.get $__s7
      )
    )
    call $__print_str
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__arr_join_any (param $xs (ref null $arr_any)) (param $sep (ref null $str)) (result (ref null $str))
    (local $n i32)
    (local $i i32)
    (local $acc (ref null $str))
    local.get $xs
    array.len
    local.set $n
    i32.const 0
    array.new_default $str
    local.set $acc
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    local.get $acc
    local.get $sep
    call $__str_concat
    local.set $acc
      )
    )
    local.get $acc
    local.get $xs
    local.get $i
    array.get $arr_any
    ref.cast (ref null $str)
    call $__str_concat
    local.set $acc
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $acc
  )
  (func $__pr1 (param $v i32)
    local.get $v
    call $__print_i32_raw
  )
  (func $__pr0 (param $v (ref null $arr_any))
    global.get $__s4
    call $__print_str_raw
    local.get $v
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__pr1
    global.get $__s5
    call $__print_str_raw
    local.get $v
    i32.const 1
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__pr1
    global.get $__s6
    call $__print_str_raw
  )
  (func $__arr_at_opt_any (param $xs (ref null $arr_any)) (param $i i32) (result anyref)
    local.get $i
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $i
    local.get $xs
    array.len
    i32.add
    local.set $i
      )
    )
    local.get $i
    i32.const 0
    i32.lt_s
    local.get $i
    local.get $xs
    array.len
    i32.ge_s
    i32.or
    (if (result anyref)
      (then
    ref.null any
      )
      (else
    local.get $xs
    local.get $i
    array.get $arr_any
      )
    )
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
  (data $__d0 "email")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "a")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "b")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 ",")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "#(")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 ", ")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 ")")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "none")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 5
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 1
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 1
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 1
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 2
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 2
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 1
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 4
    array.new_data $str $__d7
    global.set $__s7
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
a,b
0
#(1, 2)
email
none
none
```
