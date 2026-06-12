----- SOURCE CODE -- main.bp
```botopink
*fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
fn main() {
    val n = parseAge("42").unwrapOr(0);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\02\00\00\0042")
  (global $__heap_ptr (mut i32) (i32.const 264))
  (func $parseAge (param $s i32) (result i32)
    unreachable
  )
  (func $main
    (local $n i32)
    (local $_res0 i32)
    i32.const 256
    call $parseAge
    local.set $_res0
    local.get $_res0
    i32.load ;; Result tag (0 = Ok, non-zero = Error)
    (if (result i32)
      (then
    i32.const 0
      )
      (else
    local.get $_res0
    i32.load offset=4 ;; Ok payload
      )
    )
    local.set $n
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
)
```

----- RUN LOG -----
```logs
```
