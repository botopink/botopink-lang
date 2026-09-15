----- SOURCE CODE -- main.bp
```botopink
fn firstChar(s: string) -> ?string { @todo(); }
fn main() {
    val s = firstChar("abc").expect("");
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\03\00\00\00abc")
  (data (i32.const 264) "\00\00\00\00")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $firstChar (param $s i32) (result i32)
    unreachable
  )
  (func $main
    (local $s i32)
    (local $_res0 i32)
    i32.const 256
    call $firstChar
    local.set $_res0
    local.get $_res0 ;; Option (0 = None, else Some payload)
    (if (result i32)
      (then
    local.get $_res0 ;; Some — present value
      )
      (else
    i32.const 264
      )
    )
    local.set $s
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
)
```

----- RUN LOG -----
```logs
```
