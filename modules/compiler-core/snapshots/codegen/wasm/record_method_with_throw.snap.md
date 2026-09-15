----- SOURCE CODE -- main.bp
```botopink
val Invoice = record {
    subtotal: f64,
    taxRate: f64,
    fn total(self: Self) -> f64 {
        return self.subtotal + self.subtotal * self.taxRate;
    }
    fn validate(self: Self) {
        throw new Error("invalid invoice");
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\0f\00\00\00invalid invoice")
  (global $__heap_ptr (mut i32) (i32.const 276))
  (func $Invoice_total (param $self i32) (result i32)
    local.get $self
    i32.load ;; .subtotal
    local.get $self
    i32.load ;; .subtotal
    local.get $self
    i32.load offset=4 ;; .taxRate
    i32.mul
    i32.add
    return
  )
  (func $Invoice_validate (param $self i32)
    i32.const 256
    call $Error
    unreachable
  )
)
```

----- RUN LOG -----
```logs
```
