----- SOURCE CODE -- main.bp
```botopink
val Invoice = type(
    subtotal: f64,
    taxRate: f64) {
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
    (local $_res0 i32)
    global.get $__heap_ptr
    local.set $_res0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $_res0
    i32.const 1
    i32.store ;; Result tag (Error)
    local.get $_res0
    i32.const 256
    i32.store offset=4 ;; payload
    local.get $_res0
    drop
    unreachable
  )
)
```

----- RUN LOG -----
```logs
```
