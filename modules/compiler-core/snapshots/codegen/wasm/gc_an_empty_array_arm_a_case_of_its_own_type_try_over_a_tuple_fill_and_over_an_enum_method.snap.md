----- SOURCE CODE -- main.bp
```botopink
type Val {
    Num(n: i32),
    Text(s: string),

    fn str(self: Self) -> string {
        return case self {
            Text(s: t) -> t;
            _ -> "";
        };
    }
}

fn find(kind: i32) -> ?Val {
    if (kind == 1) return Val.Text(s: "a");
    if (kind == 2) return Val.Num(n: 40);
    return null;
}

fn contains(xs: string[], x: string) -> Result<void, string> {
    if (xs.indexOf(x) < 0) throw "missing";
    return;
}

fn pair(s: string) -> Result<#(string, string), string> {
    if (s == "") throw "empty";
    return #(s, s.toUpper());
}

fn label(s: string, loud: bool) -> string {
    val mark = case loud {
        true -> 1;
        false -> 0;
    };
    val parts = if (s == "") [] else [s, s];
    return parts.join("-") + mark.toString();
}

fn verdict(r: Result<void, string>) -> string {
    return case r {
        Ok(_) -> "ok";
        Error(e) -> e;
    };
}

fn both(s: string) -> Result<string, string> {
    val p = try pair(s);
    return p._0 + p._1;
}

fn text(r: Result<string, string>) -> string {
    return case r {
        Ok(v) -> v;
        Error(e) -> e;
    };
}

pub fn main() -> void {
    print(label("ab", true));
    print(label("", false));
    print("abc".contains("b"));
    print(verdict(contains(["a"], "b")));
    print(text(both("a")));
    print(text(both("")));
    print([1, 2, 3].fill("z"));
    print(find(1)?.str() ?? "none");
    print(find(3)?.str() ?? "none");
    print(Val.Num(n: 2).str().length);
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
    (type $var_Val_Num (struct (field $f0 (mut i32))))
    (type $brand_var_Val_Num (struct (field f64) (field i64) (field i64) (field i64) (field i64) (field i32) (field f32) (field i64) (field i32) (field i32) (field i32) (field f64) (field f32) (field i32) (field f64) (field i64) (field i64) (field i64) (field i64) (field f64) (field f64) (field f64) (field i64) (field i32) (field f64) (field f64) (field f64) (field f64) (field f64) (field i32) (field i64) (field f32)))
  )
  (rec
    (type $var_Val_Text (struct (field $f0 (mut (ref null $str)))))
    (type $brand_var_Val_Text (struct (field f32) (field i32) (field i32) (field i32) (field f32) (field i64) (field f32) (field i32) (field i64) (field f64) (field i64) (field f32) (field i64) (field i32) (field i32) (field i64) (field i32) (field f32) (field f64) (field i64) (field i64) (field i64) (field f32) (field i64) (field i32) (field i32) (field f32) (field i32) (field i32) (field i32) (field f32) (field i64)))
  )
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@string" "std:text.toUpper" (func $__std_text_toUpper (param i32) (result i32)))
  (import "std@string" "std:text.contains" (func $__std_text_contains (param i32 i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@number" "wat:number.i32ToString" (func $__std_number_i32ToString (param i32) (result (ref null $str))))
  (import "std@string" "wat:text.length" (func $__std_text_length (param (ref null $str)) (result i32)))
  (import "std@number" "wat:number.i64ToString" (func $__std_number_i64ToString (param i64) (result (ref null $str))))
  (import "std@number" "wat:number.u64ToString" (func $__std_number_u64ToString (param i64) (result (ref null $str))))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $Val_str (param $self anyref) (result (ref null $str))
    (local $t (ref null $str))
    (local $__case_0 anyref)
    local.get $self
    local.set $__case_0
    local.get $__case_0
    ref.test (ref null $var_Val_Text)
    local.get $__case_0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $__case_0
    ref.cast (ref null $var_Val_Text)
    struct.get $var_Val_Text $f0
    local.set $t
    local.get $t
      )
      (else
    global.get $__s0
      )
    )
    return
  )
  (func $find (param $kind i32) (result anyref)
    (local $__mem0 i32)
    (local $__mem1 i32)
    local.get $kind
    i32.const 1
    i32.eq
    (if (result anyref)
      (then
    global.get $__s1
    struct.new $var_Val_Text
    return
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $kind
    i32.const 2
    i32.eq
    (if (result anyref)
      (then
    i32.const 40
    struct.new $var_Val_Num
    return
      )
      (else
        ref.null any
      )
    )
    drop
    ref.null any
    return
  )
  (func $contains (param $xs (ref null $arr_any)) (param $x (ref null $str)) (result (ref null $result))
    local.get $xs
    local.get $x
    call $__arr_indexOf_any
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s2
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $pair (param $s (ref null $str)) (result (ref null $result))
    (local $__mem0 i32)
    (local $__gc0 (ref null $str))
    (local $__gc1 i32)
    local.get $s
    global.get $__s0
    call $__str_eq
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s3
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
    local.get $s
    local.set $__gc0
    global.get $__heap_ptr
    local.set $__gc1
    local.get $__gc0
    call $__gc_to_lin_str
    call $__std_text_toUpper
    call $__lin_to_gc_str
    local.get $__gc1
    global.set $__heap_ptr
    array.new_fixed $tuple 2
    struct.new $result
    return
  )
  (func $label (param $s (ref null $str)) (param $loud i32) (result (ref null $str))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $mark i32)
    (local $__bp_case_bool_0 i32)
    (local $parts (ref null $arr_any))
    (local $__case_0 i32)
    local.get $loud
    local.set $__case_0
    local.get $__case_0
    local.set $__bp_case_bool_0
    local.get $__bp_case_bool_0
    i32.const 1
    i32.eq
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $__case_0
    local.set $__bp_case_bool_0
    local.get $__bp_case_bool_0
    i32.const 0
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
    local.set $mark
    local.get $s
    global.get $__s0
    call $__str_eq
    (if (result (ref null $arr_any))
      (then
    array.new_fixed $arr_any 0
      )
      (else
    local.get $s
    local.get $s
    array.new_fixed $arr_any 2
      )
    )
    local.set $parts
    local.get $parts
    global.get $__s4
    call $__arr_join_any
    local.get $mark
    call $__std_number_i32ToString
    call $__str_concat
    return
  )
  (func $verdict (param $r (ref null $result)) (result (ref null $str))
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $e__0 (ref null $str))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $str))
      (then
    global.get $__s5
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $str))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $e__0
    local.get $e__0
      )
      (else
    ref.null $str
      )
    )
      )
    )
    return
  )
  (func $both (param $s (ref null $str)) (result (ref null $result))
    (local $_try0 i32)
    (local $p (ref null $arr_any))
    (local $__gc2 (ref null $result))
    local.get $s
    call $pair
    local.set $__gc2
    local.get $__gc2
    struct.get $result $tag
    (if
      (then
    local.get $__gc2
    return ;; propagate Error
      )
    )
    local.get $__gc2
    struct.get $result $payload
    ref.cast (ref null $arr_any)
    local.set $p
    i32.const 0
    local.get $p
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $str)
    local.get $p
    i32.const 1
    array.get $arr_any
    ref.cast (ref null $str)
    call $__str_concat
    struct.new $result
    return
  )
  (func $text (param $r (ref null $result)) (result (ref null $str))
    (local $v i32)
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $v__1 (ref null $str))
    (local $e__2 (ref null $str))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $v__1
    local.get $v__1
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $str))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $e__2
    local.get $e__2
      )
      (else
    ref.null $str
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
    (local $__bp_nullish i32)
    (local $__gc3 (ref null $str))
    (local $__gc4 (ref null $str))
    (local $__gc5 i32)
    (local $__fill0 (ref null $arr_i32))
    (local $__opt1 (ref null $str))
    (local $__gc6 anyref)
    (local $__bp_nullish__3 (ref null $str))
    (local $__opt2 (ref null $str))
    (local $__gc7 anyref)
    (local $__bp_nullish__4 (ref null $str))
    global.get $__s6
    i32.const 1
    call $label
    call $__print_str
    global.get $__s0
    i32.const 0
    call $label
    call $__print_str
    global.get $__s7
    global.get $__s8
    local.set $__gc3
    local.set $__gc4
    global.get $__heap_ptr
    local.set $__gc5
    local.get $__gc4
    call $__gc_to_lin_str
    local.get $__gc3
    call $__gc_to_lin_str
    call $__std_text_contains
    local.get $__gc5
    global.set $__heap_ptr
    call $__print_bool
    global.get $__s1
    array.new_fixed $arr_any 1
    global.get $__s8
    call $contains
    call $verdict
    call $__print_str
    global.get $__s1
    call $both
    call $text
    call $__print_str
    global.get $__s0
    call $both
    call $text
    call $__print_str
    i32.const 1
    i32.const 2
    i32.const 3
    array.new_fixed $arr_i32 3
    local.set $__fill0
    global.get $__s12
    local.get $__fill0
    array.len
    array.new $arr_any
    call $__pr0
    call $__print_nl
    i32.const 1
    call $find
    local.tee $__gc6
    ref.is_null
    (if (result (ref null $str))
      (then
    ref.null $str
      )
      (else
    local.get $__gc6
    call $Val_str
      )
    )
    local.tee $__opt1
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt1
    local.set $__bp_nullish__3
    local.get $__bp_nullish__3
      )
      (else
    global.get $__s13
      )
    )
    call $__print_str
    i32.const 3
    call $find
    local.tee $__gc7
    ref.is_null
    (if (result (ref null $str))
      (then
    ref.null $str
      )
      (else
    local.get $__gc7
    call $Val_str
      )
    )
    local.tee $__opt2
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt2
    local.set $__bp_nullish__4
    local.get $__bp_nullish__4
      )
      (else
    global.get $__s13
      )
    )
    call $__print_str
    i32.const 2
    struct.new $var_Val_Num
    call $Val_str
    call $__std_text_length
    call $__print_i32
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__arr_indexOf_any (param $xs (ref null $arr_any)) (param $x (ref null $str)) (result i32)
    (local $n i32)
    (local $i i32)
    local.get $xs
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $xs
    local.get $i
    array.get $arr_any
    ref.cast (ref null $str)
    local.get $x
    call $__str_eq
    (if
      (then
    local.get $i
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
    i32.const -1
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
  (func $__pr1 (param $v (ref null $str))
    local.get $v
    call $__print_quoted_raw
  )
  (func $__pr0 (param $v (ref null $arr_any))
    (local $n i32)
    (local $i i32)
    global.get $__s9
    call $__print_str_raw
    local.get $v
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    global.get $__s10
    call $__print_str_raw
      )
    )
    local.get $v
    local.get $i
    array.get $arr_any
    ref.cast (ref null $str)
    call $__pr1
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    global.get $__s11
    call $__print_str_raw
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
  (func $__gc_to_lin_str (param $s (ref null $str)) (result i32)
    (local $n i32) (local $p i32) (local $i i32)
    local.get $s
    array.len
    local.set $n
    local.get $n
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
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
        i32.store8 offset=4
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
  )
  (func $__lin_to_gc_str (param $p i32) (result (ref null $str))
    (local $r (ref null $str)) (local $n i32) (local $i i32)
    local.get $p
    i32.load
    local.set $n
    local.get $n
    array.new_default $str
    local.set $r
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $r
        local.get $i
        local.get $p
        local.get $i
        i32.add
        i32.load8_u offset=4
        array.set $str
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $r
  )
  (data $__d0 "")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "a")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "missing")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "empty")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "-")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "ok")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "ab")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "abc")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "b")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "[")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 ", ")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 "]")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (data $__d12 "z")
  (global $__s12 (mut (ref null $str)) (ref.null $str))
  (data $__d13 "none")
  (global $__s13 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 0
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 1
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 7
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 5
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 1
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 2
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 2
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 3
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 1
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 1
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 2
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 1
    array.new_data $str $__d11
    global.set $__s11
    i32.const 0
    i32.const 1
    array.new_data $str $__d12
    global.set $__s12
    i32.const 0
    i32.const 4
    array.new_data $str $__d13
    global.set $__s13
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
ab-ab1
0
true
missing
aA
empty
["z", "z", "z"]
a
none
0
```
