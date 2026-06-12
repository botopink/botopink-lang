----- SOURCE CODE -- main.bp
```botopink
val Counter = struct {
    count: i32 = 0,
    fn inc() {
        self.count += 1;
    }
};
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $Counter_inc (param $self i32)
    (local $__mem0 i32)
    local.get $self
    local.set $__mem0
    local.get $__mem0
    local.get $__mem0
    i32.load
    i32.const 1
    i32.add
    i32.store ;; .count +=
  )
)
```

----- RUN LOG -----
```logs
```
