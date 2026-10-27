----- SOURCE CODE -- std/functions.bp
```botopink
//// std/functions — combinators over function values (decision 738).
////
//// Plain functions of a std module, imported by path:
//// `import {functions.compose} from "std";`. A function's type is
//// `fn(A) -> B`; no `Function` contract names it. Pure botopink, no host
//// backing, so the module runs on every target.
////
//// No import (decision 106: a root module).

/// The argument, unchanged.
pub fn identity<A>(x: A) -> A {
    return x;
}

/// `f`, then `g`: `compose(f, g)(a)` is `g(f(a))`.
pub fn compose<A, B, C>(f: fn(a: A) -> B, g: fn(b: B) -> C) -> fn(A) -> C {
    return { a -> g(f(a)) };
}

/// `f` with its two arguments swapped: `flip(f)(b, a)` is `f(a, b)`.
pub fn flip<A, B, C>(f: fn(a: A, b: B) -> C) -> fn(B, A) -> C {
    return { b, a -> f(a, b) };
}

/// A function answering `x` whatever it is given. The argument is typed
/// `unknown` (decision 668: no parameter would bind a type for it), so one
/// binding takes any argument.
pub fn constant<A>(x: A) -> fn(unknown) -> A {
    return { ignored -> x };
}

test "functions.identity" {
    assert identity(42) == 42;
    assert identity("hi") == "hi";
    assert identity(true);
}

test "functions.compose runs left to right" {
    val double: fn(i32) -> i32 = { n -> n * 2 };
    val addOne: fn(i32) -> i32 = { n -> n + 1 };
    val f = compose(double, addOne);
    assert f(3) == 7;
    assert f(0) == 1;
}

test "functions.compose with a string transform" {
    val shout: fn(string) -> string = { s -> s + "!" };
    val greet: fn(string) -> string = { s -> "Hello, " + s };
    val greetAndShout = compose(greet, shout);
    assert greetAndShout("world") == "Hello, world!";
}

test "functions.flip reverses the argument order" {
    val sub: fn(i32, i32) -> i32 = { a, b -> a - b };
    val rsub = flip(sub);
    assert rsub(3, 10) == 7;
}

test "functions.constant ignores its argument" {
    val always42 = constant(42);
    assert always42("anything") == 42;
    assert always42(0) == 42;
}

```

----- WASM TEXT -- std/functions.wat
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
    (type $env0 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut (ref null $closure))) (field $c1 (mut (ref null $closure))))))
    (type $env1 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut (ref null $closure))))))
    (type $env2 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut anyref)))))
  )
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (elem declare func $__lambda0 $__lambda1 $__lambda2)
  ;; std/functions — combinators over function values (decision 738).
  ;; 
  ;; Plain functions of a std module, imported by path:
  ;; `import {functions.compose} from "std";`. A function's type is
  ;; `fn(A) -> B`; no `Function` contract names it. Pure botopink, no host
  ;; backing, so the module runs on every target.
  ;; 
  ;; No import (decision 106: a root module).
  ;; The argument, unchanged.
  (func $identity (export "identity") (param $x anyref) (result anyref)
    local.get $x
    return
  )
  ;; `f`, then `g`: `compose(f, g)(a)` is `g(f(a))`.
  (func $compose (export "compose") (param $f (ref null $closure)) (param $g (ref null $closure)) (result (ref null $closure))
    ref.func $__lambda0
    i32.const 1 ;; arity
    i32.const 0
    local.get $g ;; capture g
    local.get $f ;; capture f
    struct.new $env0
    return
  )
  ;; `f` with its two arguments swapped: `flip(f)(b, a)` is `f(a, b)`.
  (func $flip (export "flip") (param $f (ref null $closure)) (result (ref null $closure))
    ref.func $__lambda1
    i32.const 2 ;; arity
    i32.const 0
    local.get $f ;; capture f
    struct.new $env1
    return
  )
  ;; A function answering `x` whatever it is given. The argument is typed
  ;; `unknown` (decision 668: no parameter would bind a type for it), so one
  ;; binding takes any argument.
  (func $constant (export "constant") (param $x anyref) (result (ref null $closure))
    ref.func $__lambda2
    i32.const 1 ;; arity
    i32.const 0
    local.get $x ;; capture x
    struct.new $env2
    return
  )
  (func $__lambda0__b (param $__env (ref null $env0)) (param $a anyref) (result anyref)
    (local $g (ref null $closure))
    (local $f (ref null $closure))
    (local $__fnv0 (ref null $closure))
    (local $__fnv1 (ref null $closure))
    local.get $__env
    struct.get $env0 $c0
    local.set $g
    local.get $__env
    struct.get $env0 $c1
    local.set $f
    local.get $g
    local.set $__fnv0
    local.get $__fnv0
    local.get $f
    local.set $__fnv1
    local.get $__fnv1
    local.get $a
    local.get $__fnv1
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_1)
    call_ref $sig_1
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_1)
    call_ref $sig_1
  )
  (func $__lambda0 (type $sig_1) (param $__env (ref null $closure)) (param $__a0 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env0)
    local.get $__a0
    call $__lambda0__b
  )
  (func $__lambda1__b (param $__env (ref null $env1)) (param $b anyref) (param $a anyref) (result anyref)
    (local $f (ref null $closure))
    (local $__fnv0 (ref null $closure))
    local.get $__env
    struct.get $env1 $c0
    local.set $f
    local.get $f
    local.set $__fnv0
    local.get $__fnv0
    local.get $a
    local.get $b
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_2)
    call_ref $sig_2
  )
  (func $__lambda1 (type $sig_2) (param $__env (ref null $closure)) (param $__a0 anyref) (param $__a1 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env1)
    local.get $__a0
    local.get $__a1
    call $__lambda1__b
  )
  (func $__lambda2__b (param $__env (ref null $env2)) (param $ignored anyref) (result anyref)
    (local $x anyref)
    local.get $__env
    struct.get $env2 $c0
    local.set $x
    local.get $x
  )
  (func $__lambda2 (type $sig_1) (param $__env (ref null $closure)) (param $__a0 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env2)
    local.get $__a0
    call $__lambda2__b
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn parse(s: string) -> Result<array<#(string, string)>, string> {
    if (s == "") throw "empty";
    return [#(s, s.toUpper())];
}

fn pairsOf(r: Result<array<#(string, string)>, string>) -> string {
    val none: array<#(string, string)> = [];
    return r.unwrapOr(none).map({ p -> [p._0, "=>", p._1].join("") }).join("|");
}

pub fn main() -> void {
    print(pairsOf(parse("a")));
    print(pairsOf(parse("")).length);
    val double: fn(i32) -> i32 = { n -> n * 2 };
    val addOne: fn(i32) -> i32 = { n -> n + 1 };
    print(functions.compose(double, addOne)(3));
    val shout: fn(string) -> string = { s -> s + "!" };
    print(functions.compose(shout, shout)("hi"));
    val sub: fn(i32, i32) -> i32 = { a, b -> a - b };
    print(functions.flip(sub)(3, 10));
    print(functions.constant(42)("x"));
}

import {io.terminal.print} from "std";
import {functions} from "std";
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
    (type $env0 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut (ref null $closure))) (field $c1 (mut (ref null $closure))))))
    (type $env1 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut (ref null $closure))))))
    (type $env2 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut anyref)))))
    (type $env3 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $env4 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $env5 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $env6 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $env7 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut (ref null $closure))) (field $c1 (mut (ref null $closure))))))
    (type $env8 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut (ref null $closure))) (field $c1 (mut (ref null $closure))))))
    (type $env9 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut (ref null $closure))))))
    (type $env10 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut i32)))))
  )
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@string" "std:text.toUpper" (func $__std_text_toUpper (param i32) (result i32)))
  (import "std@string" "wat:text.length" (func $__abi___std_text_length (param arrayref) (result i32)))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (elem declare func $__lambda0 $__lambda1 $__lambda2 $__lambda3 $__lambda4 $__lambda5 $__lambda6 $__lambda7 $__lambda8 $__lambda9 $__lambda10)
  (func $compose (param $f (ref null $closure)) (param $g (ref null $closure)) (result (ref null $closure))
    ref.func $__lambda0
    i32.const 1 ;; arity
    i32.const 0
    local.get $g ;; capture g
    local.get $f ;; capture f
    struct.new $env0
    return
  )
  (func $flip (param $f (ref null $closure)) (result (ref null $closure))
    ref.func $__lambda1
    i32.const 2 ;; arity
    i32.const 0
    local.get $f ;; capture f
    struct.new $env1
    return
  )
  (func $constant (param $x anyref) (result (ref null $closure))
    ref.func $__lambda2
    i32.const 1 ;; arity
    i32.const 0
    local.get $x ;; capture x
    struct.new $env2
    return
  )
  (func $parse (param $s (ref null $str)) (result (ref null $result))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__gc0 (ref null $str))
    (local $__gc1 i32)
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
    array.new_fixed $arr_any 1
    struct.new $result
    return
  )
  (func $pairsOf (param $r (ref null $result)) (result (ref null $str))
    (local $__mem0 i32)
    (local $none (ref null $arr_any))
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $p (ref null $arr_any))
    (local $__gc2 (ref null $result))
    (local $__out0 (ref null $arr_any))
    array.new_fixed $arr_any 0
    local.set $none
    local.get $r
    local.tee $__gc2
    struct.get $result $tag
    (if (result (ref null $arr_any))
      (then
    local.get $none
      )
      (else
    local.get $__gc2
    struct.get $result $payload
    ref.cast (ref null $arr_any)
      )
    )
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $arr_any)
        local.set $p
    local.get $__out0
    local.get $__idx0
    local.get $p
    i32.const 0
    array.get $arr_any
    ref.cast (ref null $str)
    global.get $__s2
    local.get $p
    i32.const 1
    array.get $arr_any
    ref.cast (ref null $str)
    array.new_fixed $arr_any 3
    global.get $__s0
    call $__arr_join_any
    array.set $arr_any
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    global.get $__s3
    call $__arr_join_any
    return
  )
  (func $main (export "main")
    (local $double (ref null $closure))
    (local $addOne (ref null $closure))
    (local $shout (ref null $closure))
    (local $sub (ref null $closure))
    (local $__fnv0 (ref null $closure))
    (local $__fnv1 (ref null $closure))
    (local $__fnv2 (ref null $closure))
    (local $__fnv3 (ref null $closure))
    global.get $__s4
    call $parse
    call $pairsOf
    call $__print_str
    global.get $__s0
    call $parse
    call $pairsOf
    call $__std_text_length
    call $__print_i32
    ref.func $__lambda3
    i32.const 1 ;; arity
    i32.const 0
    struct.new $env3
    local.set $double
    ref.func $__lambda4
    i32.const 1 ;; arity
    i32.const 0
    struct.new $env4
    local.set $addOne
    local.get $double
    local.get $addOne
    call $compose__B_i32__C_i32
    local.set $__fnv0
    local.get $__fnv0
    i32.const 3
    struct.new $box_i32
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_1)
    call_ref $sig_1
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32
    ref.func $__lambda5
    i32.const 1 ;; arity
    i32.const 0
    struct.new $env5
    local.set $shout
    local.get $shout
    local.get $shout
    call $compose__B_string__C_string
    local.set $__fnv1
    local.get $__fnv1
    global.get $__s5
    local.get $__fnv1
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_1)
    call_ref $sig_1
    ref.cast (ref null $str)
    call $__print_str
    ref.func $__lambda6
    i32.const 2 ;; arity
    i32.const 0
    struct.new $env6
    local.set $sub
    local.get $sub
    call $flip__C_i32
    local.set $__fnv2
    local.get $__fnv2
    i32.const 3
    struct.new $box_i32
    i32.const 10
    struct.new $box_i32
    local.get $__fnv2
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_2)
    call_ref $sig_2
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32
    i32.const 42
    call $constant__A_i32
    local.set $__fnv3
    local.get $__fnv3
    global.get $__s6
    local.get $__fnv3
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_1)
    call_ref $sig_1
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32
  )
  (func $compose__B_i32__C_i32 (param $f (ref null $closure)) (param $g (ref null $closure)) (result (ref null $closure))
    ref.func $__lambda7
    i32.const 1 ;; arity
    i32.const 0
    local.get $g ;; capture g
    local.get $f ;; capture f
    struct.new $env7
    return
  )
  (func $compose__B_string__C_string (param $f (ref null $closure)) (param $g (ref null $closure)) (result (ref null $closure))
    ref.func $__lambda8
    i32.const 1 ;; arity
    i32.const 0
    local.get $g ;; capture g
    local.get $f ;; capture f
    struct.new $env8
    return
  )
  (func $flip__C_i32 (param $f (ref null $closure)) (result (ref null $closure))
    ref.func $__lambda9
    i32.const 2 ;; arity
    i32.const 0
    local.get $f ;; capture f
    struct.new $env9
    return
  )
  (func $constant__A_i32 (param $x i32) (result (ref null $closure))
    ref.func $__lambda10
    i32.const 1 ;; arity
    i32.const 0
    local.get $x ;; capture x
    struct.new $env10
    return
  )
  (func $__lambda0__b (param $__env (ref null $env0)) (param $a anyref) (result anyref)
    (local $g (ref null $closure))
    (local $f (ref null $closure))
    (local $__fnv0 (ref null $closure))
    (local $__fnv1 (ref null $closure))
    local.get $__env
    struct.get $env0 $c0
    local.set $g
    local.get $__env
    struct.get $env0 $c1
    local.set $f
    local.get $g
    local.set $__fnv0
    local.get $__fnv0
    local.get $f
    local.set $__fnv1
    local.get $__fnv1
    local.get $a
    local.get $__fnv1
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_1)
    call_ref $sig_1
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_1)
    call_ref $sig_1
  )
  (func $__lambda0 (type $sig_1) (param $__env (ref null $closure)) (param $__a0 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env0)
    local.get $__a0
    call $__lambda0__b
  )
  (func $__lambda1__b (param $__env (ref null $env1)) (param $b anyref) (param $a anyref) (result anyref)
    (local $f (ref null $closure))
    (local $__fnv0 (ref null $closure))
    local.get $__env
    struct.get $env1 $c0
    local.set $f
    local.get $f
    local.set $__fnv0
    local.get $__fnv0
    local.get $a
    local.get $b
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_2)
    call_ref $sig_2
  )
  (func $__lambda1 (type $sig_2) (param $__env (ref null $closure)) (param $__a0 anyref) (param $__a1 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env1)
    local.get $__a0
    local.get $__a1
    call $__lambda1__b
  )
  (func $__lambda2__b (param $__env (ref null $env2)) (param $ignored anyref) (result anyref)
    (local $x anyref)
    local.get $__env
    struct.get $env2 $c0
    local.set $x
    local.get $x
  )
  (func $__lambda2 (type $sig_1) (param $__env (ref null $closure)) (param $__a0 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env2)
    local.get $__a0
    call $__lambda2__b
  )
  (func $__lambda3__b (param $__env (ref null $env3)) (param $n i32) (result i32)
    local.get $n
    i32.const 2
    global.get $__s7
    call $__i32_mul_chk
  )
  (func $__lambda3 (type $sig_1) (param $__env (ref null $closure)) (param $__a0 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env3)
    local.get $__a0
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__lambda3__b
    struct.new $box_i32
  )
  (func $__lambda4__b (param $__env (ref null $env4)) (param $n i32) (result i32)
    local.get $n
    i32.const 1
    global.get $__s8
    call $__i32_add_chk
  )
  (func $__lambda4 (type $sig_1) (param $__env (ref null $closure)) (param $__a0 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env4)
    local.get $__a0
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__lambda4__b
    struct.new $box_i32
  )
  (func $__lambda5__b (param $__env (ref null $env5)) (param $s (ref null $str)) (result (ref null $str))
    local.get $s
    global.get $__s9
    call $__str_concat
  )
  (func $__lambda5 (type $sig_1) (param $__env (ref null $closure)) (param $__a0 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env5)
    local.get $__a0
    ref.cast (ref null $str)
    call $__lambda5__b
  )
  (func $__lambda6__b (param $__env (ref null $env6)) (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    global.get $__s10
    call $__i32_sub_chk
  )
  (func $__lambda6 (type $sig_2) (param $__env (ref null $closure)) (param $__a0 anyref) (param $__a1 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env6)
    local.get $__a0
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.get $__a1
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__lambda6__b
    struct.new $box_i32
  )
  (func $__lambda7__b (param $__env (ref null $env7)) (param $a anyref) (result i32)
    (local $g (ref null $closure))
    (local $f (ref null $closure))
    (local $__fnv0 (ref null $closure))
    (local $__fnv1 (ref null $closure))
    local.get $__env
    struct.get $env7 $c0
    local.set $g
    local.get $__env
    struct.get $env7 $c1
    local.set $f
    local.get $g
    local.set $__fnv0
    local.get $__fnv0
    local.get $f
    local.set $__fnv1
    local.get $__fnv1
    local.get $a
    local.get $__fnv1
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_1)
    call_ref $sig_1
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    struct.new $box_i32
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_1)
    call_ref $sig_1
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
  )
  (func $__lambda7 (type $sig_1) (param $__env (ref null $closure)) (param $__a0 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env7)
    local.get $__a0
    call $__lambda7__b
    struct.new $box_i32
  )
  (func $__lambda8__b (param $__env (ref null $env8)) (param $a anyref) (result (ref null $str))
    (local $g (ref null $closure))
    (local $f (ref null $closure))
    (local $__fnv0 (ref null $closure))
    (local $__fnv1 (ref null $closure))
    local.get $__env
    struct.get $env8 $c0
    local.set $g
    local.get $__env
    struct.get $env8 $c1
    local.set $f
    local.get $g
    local.set $__fnv0
    local.get $__fnv0
    local.get $f
    local.set $__fnv1
    local.get $__fnv1
    local.get $a
    local.get $__fnv1
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_1)
    call_ref $sig_1
    ref.cast (ref null $str)
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_1)
    call_ref $sig_1
    ref.cast (ref null $str)
  )
  (func $__lambda8 (type $sig_1) (param $__env (ref null $closure)) (param $__a0 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env8)
    local.get $__a0
    call $__lambda8__b
  )
  (func $__lambda9__b (param $__env (ref null $env9)) (param $b anyref) (param $a anyref) (result i32)
    (local $f (ref null $closure))
    (local $__fnv0 (ref null $closure))
    local.get $__env
    struct.get $env9 $c0
    local.set $f
    local.get $f
    local.set $__fnv0
    local.get $__fnv0
    local.get $a
    local.get $b
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_2)
    call_ref $sig_2
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
  )
  (func $__lambda9 (type $sig_2) (param $__env (ref null $closure)) (param $__a0 anyref) (param $__a1 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env9)
    local.get $__a0
    local.get $__a1
    call $__lambda9__b
    struct.new $box_i32
  )
  (func $__lambda10__b (param $__env (ref null $env10)) (param $ignored anyref) (result i32)
    (local $x i32)
    local.get $__env
    struct.get $env10 $c0
    local.set $x
    local.get $x
  )
  (func $__lambda10 (type $sig_1) (param $__env (ref null $closure)) (param $__a0 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env10)
    local.get $__a0
    call $__lambda10__b
    struct.new $box_i32
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
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  (func $__std_text_length (param $p0 (ref null $str)) (result i32)
    local.get $p0
    call $__abi___std_text_length
  )
  (data $__d0 "")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "empty")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "=>")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "|")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "a")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "hi")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "x")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "integer overflow: * on i32 at main.bp:14:43")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "integer overflow: + on i32 at main.bp:15:43")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "!")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "integer overflow: - on i32 at main.bp:19:48")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 0
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 5
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 2
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 1
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
    i32.const 1
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 43
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 43
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 1
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 43
    array.new_data $str $__d10
    global.set $__s10
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
a=>A
0
7
hi!!
7
42
```
