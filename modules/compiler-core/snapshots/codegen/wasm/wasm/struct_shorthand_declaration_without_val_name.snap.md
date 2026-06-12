----- SOURCE CODE -- main.bp
```botopink
struct Counter {
    _count: i32 = 0,
    fn increment(self: Self) {
        self._count += 1;
    }
    get count(self: Self) -> i32 {
        return self._count;
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $Counter_increment (param $self i32)
    (local $__mem0 i32)
    local.get $self
    local.set $__mem0
    local.get $__mem0
    local.get $__mem0
    i32.load
    i32.const 1
    i32.add
    i32.store ;; ._count +=
  )
)
```

----- RUN LOG -----
```logs
```
