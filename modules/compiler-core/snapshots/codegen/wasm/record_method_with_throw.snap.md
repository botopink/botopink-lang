----- SOURCE CODE -- main.bp
```botopink
val Invoice = type(
    subtotal: f64,
    taxRate: f64) {
    fn total(self: Self) -> f64 {
        return self.subtotal + self.subtotal * self.taxRate;
    }
    fn validate(self: Self) -> Result<void, string> {
        throw "invalid invoice";
        return;
    }
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
    (type $rec_Invoice (struct (field $f0 (mut f64)) (field $f1 (mut f64))))
    (type $brand_rec_Invoice (struct (field i32) (field i32) (field i64) (field f64) (field f32) (field f64) (field i64) (field i64) (field i64) (field f32) (field i64) (field i32) (field i64) (field i64) (field i32) (field i64) (field i64) (field f64) (field f32) (field f32) (field f32) (field i32) (field f64) (field f32) (field f64) (field f64) (field f32) (field i64) (field i64) (field i64) (field f64) (field f32)))
  )
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $Invoice_total (param $self (ref null $rec_Invoice)) (result f64)
    local.get $self
    struct.get $rec_Invoice $f0
    local.get $self
    struct.get $rec_Invoice $f0
    local.get $self
    struct.get $rec_Invoice $f1
    f64.mul
    f64.add
    return
  )
  (func $Invoice_validate (param $self (ref null $rec_Invoice)) (result (ref null $result))
    i32.const 1
    global.get $__s0
    struct.new $result
    return
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  (data $__d0 "invalid invoice")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 15
    array.new_data $str $__d0
    global.set $__s0
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
