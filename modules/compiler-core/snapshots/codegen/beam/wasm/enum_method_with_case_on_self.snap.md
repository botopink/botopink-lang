----- SOURCE CODE -- main.bp
```botopink
val Color = type {
    Red,
    Green,
    Blue,
    fn name(self: Self) -> string {
        case (self) {
            Red -> "red";
            Green -> "green";
            Blue -> "blue";
        };
    }
};
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\03\00\00\00red")
  (data (i32.const 264) "\05\00\00\00green")
  (data (i32.const 276) "\04\00\00\00blue")
  (global $__heap_ptr (mut i32) (i32.const 284))
  (func $Color_name (param $self i32) (result i32)
    (local $__case_0 i32)
    local.get $self
    local.set $__case_0
    local.get $__case_0
    i32.const 0 ;; Red
    i32.eq
    (if (result i32)
      (then
    i32.const 256
      )
      (else
    local.get $__case_0
    i32.const 1 ;; Green
    i32.eq
    (if (result i32)
      (then
    i32.const 264
      )
      (else
    local.get $__case_0
    i32.const 2 ;; Blue
    i32.eq
    (if (result i32)
      (then
    i32.const 276
      )
      (else
    i32.const 0
      )
    )
      )
    )
      )
    )
  )
)
```

----- RUN LOG -----
```logs
```
