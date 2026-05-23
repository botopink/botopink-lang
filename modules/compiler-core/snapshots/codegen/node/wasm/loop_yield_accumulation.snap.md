----- SOURCE CODE -- main.bp
```botopink
fn doubles(arr: i32[]) -> i32[] {
    return loop (arr) { x ->
        yield x * 2;
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $doubles (param $arr i32) (result i32)
    i32.const 0 ;; loop over non-range
    return
  )
)
```

----- RUN LOG -----
```logs
```
