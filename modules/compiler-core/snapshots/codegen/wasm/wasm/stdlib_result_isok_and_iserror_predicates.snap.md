----- SOURCE CODE -- main.bp
```botopink
*fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
fn main() {
    val r = parseAge("42");
    val ok = r.isOk();
    val bad = r.isError();
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
    (local $ok i32)
    (local $bad i32)
    i32.const 256
    call $parseAge
    local.set $r
    local.get $r
    i32.load ;; Result tag
    i32.eqz ;; isOk = (tag == 0)
    local.set $ok
    local.get $r
    i32.load ;; Result tag
    i32.const 0
    i32.ne ;; isError = (tag != 0)
    local.set $bad
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
)
```

----- RUN LOG -----
```logs
```
