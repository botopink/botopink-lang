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
    (type $rec_Invoice (struct (field $f0 (mut f64)) (field $f1 (mut f64))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $box_i32 (struct (field $v i32)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
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
