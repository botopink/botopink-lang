----- SOURCE CODE -- main.bp
```botopink
val Shape = type {
    Circle(r: i32),
    Square(s: i32),
}
fn big(sh: Shape) -> string {
    return case sh {
        Circle(r) if r > 10 -> "big circle";
        _ -> "other";
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\0a\00\00\00big circle")
  (data (i32.const 272) "\05\00\00\00other")
  (global $__heap_ptr (mut i32) (i32.const 284))
  (func $big (param $sh i32) (result i32)
    (local $r i32)
    (local $__case_0 i32)
    local.get $sh
    local.set $__case_0
    local.get $__case_0
    i32.load ;; variant tag
    i32.const 0 ;; Circle
    i32.eq
    (if (result i32)
      (then
    local.get $__case_0
    i32.load offset=4
    local.set $r
    i32.const 256
      )
      (else
    i32.const 272
      )
    )
    return
  )
)
```

----- RUN LOG -----
```logs
```
