----- SOURCE CODE -- main.bp
```botopink
val Invoice = type(
    subtotal: f64,
    taxRate: f64) {
    fn total(self: Self) -> f64 {
        return self.subtotal + self.subtotal * self.taxRate;
    }
    fn validate(self: Self) {
        throw "invalid invoice";
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\0f\00\00\00invalid invoice")
  (global $__heap_ptr (mut i32) (i32.const 276))
  (func $Invoice_total (param $self i32) (result f64)
    local.get $self
    i32.load ;; .subtotal
    f64.load
    local.get $self
    i32.load ;; .subtotal
    f64.load
    local.get $self
    i32.load offset=4 ;; .taxRate
    f64.load
    f64.mul
    f64.add
    return
  )
  (func $Invoice_validate (param $self i32)
    i32.const 256
    drop
    unreachable
  )
)
```

----- RUN LOG -----
```logs
```
