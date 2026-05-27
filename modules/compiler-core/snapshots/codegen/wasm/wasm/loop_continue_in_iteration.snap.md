----- SOURCE CODE -- main.bp
```botopink
fn sumEvens(arr: i32[]) -> i32 {
    return loop (arr) { x ->
        if (x % 2 != 0) { continue; };
        yield x;
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $sumEvens (param $arr i32) (result i32)
    i32.const 0 ;; loop over non-range
    return
  )
)
```

----- RUN LOG -----
```logs
```
