----- SOURCE CODE -- main.bp
```botopink
*fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
fn main() {
    val r = parseAge("42").map({ n -> n + 1 });
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
    (local $r i32)
    (local $_res0 i32)
    i32.const 256
    call $parseAge
    local.set $_res0
    local.get $_res0
    i32.load ;; Result tag (0 = Ok, non-zero = Error)
    (if (result i32)
      (then
    local.get $_res0 ;; Error — propagate unchanged
      )
      (else
    local.get $_res0
    i32.load offset=4 ;; Ok payload
    local.set $_res0
    (local $n i32)
    local.get $_res0
    local.set $n
    (local $_res1 i32)
    global.get $__heap_ptr
    local.set $_res1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $_res1
    i32.const 0
    i32.store ;; Ok tag
    local.get $_res1
    local.get $n
    i32.const 1
    i32.add
    i32.store offset=4 ;; mapped payload
    local.get $_res1
      )
    )
    local.set $r
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
)
```

----- RUN LOG -----
```logs
```
