----- SOURCE CODE -- std/order.bp
```botopink
//// Gleam-style `order` module, inspired by `gleam/order`. A sum type — the
//// `enum Order` (type-exported to importers) plus companion functions.
//// Construct via the module fns (`order.lt()`); `toInt`/`reverse` operate on
//// an `Order`. Enums are concrete types, not interfaces.

pub enum Order {
    Lt,
    Eq,
    Gt,
}

pub fn lt() -> Order {
    return Order.Lt;
}

pub fn eq() -> Order {
    return Order.Eq;
}

pub fn gt() -> Order {
    return Order.Gt;
}

pub fn toInt(o: Order) -> i32 {
    val n = case o {
        Lt -> -1;
        Eq -> 0;
        _ -> 1;
    };
    return n;
}

pub fn reverse(o: Order) -> Order {
    val r = case o {
        Lt -> Order.Gt;
        Gt -> Order.Lt;
        _ -> Order.Eq;
    };
    return r;
}

test "order toInt" {
    assert toInt(lt()) == -1;
    assert toInt(eq()) == 0;
    assert toInt(gt()) == 1;
}

test "order reverse" {
    assert toInt(reverse(lt())) == 1;
    assert toInt(reverse(gt())) == -1;
    assert toInt(reverse(eq())) == 0;
}

test "order case over Order" {
    val o = reverse(lt());
    val s = case o {
        Lt -> "less";
        Gt -> "greater";
        _ -> "equal";
    };
    assert s == "greater";
}

```

----- WASM TEXT -- std/order.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; Gleam-style `order` module, inspired by `gleam/order`. A sum type — the
  ;; `enum Order` (type-exported to importers) plus companion functions.
  ;; Construct via the module fns (`order.lt()`); `toInt`/`reverse` operate on
  ;; an `Order`. Enums are concrete types, not interfaces.
  (func $lt (export "lt") (result i32)
    i32.const 0 ;; Order.Lt
    return
  )
  (func $eq (export "eq") (result i32)
    i32.const 1 ;; Order.Eq
    return
  )
  (func $gt (export "gt") (result i32)
    i32.const 2 ;; Order.Gt
    return
  )
  (func $toInt (export "toInt") (param $o i32) (result i32)
    (local $n i32)
    local.get $o
    (local $__case_0 i32)
    local.set $__case_0
    i32.const 0
    i32.const 1
    i32.sub
    local.set $n
    local.get $n
    return
  )
  (func $reverse (export "reverse") (param $o i32) (result i32)
    (local $r i32)
    local.get $o
    (local $__case_0 i32)
    local.set $__case_0
    i32.const 2 ;; Order.Gt
    local.set $r
    local.get $r
    return
  )
)
```

----- RUN LOG -----
```logs
Execution error: error.FileNotFound```

----- SOURCE CODE -- main.bp
```botopink
import {order} from "std";

fn describe(o: Order) -> string {
    val s = case o {
        Lt -> "less";
        Gt -> "greater";
        _ -> "equal";
    };
    return s;
}

fn main() {
    @print(order.toInt(order.lt()));
    @print(describe(order.reverse(order.lt())));
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\04\00\00\00less")
  (global $__heap_ptr (mut i32) (i32.const 264))
  (func $describe (param $o i32) (result i32)
    (local $s i32)
    local.get $o
    (local $__case_0 i32)
    local.set $__case_0
    i32.const 256
    local.set $s
    local.get $s
    return
  )
  (func $main
    call $lt
    call $toInt
    call $__print_i32
    drop
    call $lt
    call $reverse
    call $describe
    call $__print_i32
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__print_i32 (param $n i32)
    (local $buf i32) (local $len i32) (local $neg i32) (local $d i32)
    (local $i i32) (local $j i32) (local $tmp i32)
    i32.const 100
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
    local.get $neg
    (if
      (then
        local.get $buf
        local.get $len
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
    i32.add
    i32.const 10
    i32.store8
    local.get $len
    i32.const 1
    i32.add
    local.set $len
    ;; fd_write
    i32.const 0
    local.get $buf
    i32.store
    i32.const 4
    local.get $len
    i32.store
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
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
)
```

----- RUN LOG -----
```logs
```
