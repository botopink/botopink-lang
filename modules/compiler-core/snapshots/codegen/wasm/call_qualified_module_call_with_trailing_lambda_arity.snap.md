----- SOURCE CODE -- main.bp
```botopink
type List(tag: i32) {
    fn each(items: i32[], f: fn() -> i32) -> i32[] {
        return items;
    }
}
type Pipeline(
    items: i32[]) {
    fn doubled(self: Self) -> i32[] {
        return List.each(self.items) { ->
            return 2;
        };
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $List_each (param $items i32) (param $f i32) (result i32)
    local.get $items
    return
  )
  (func $Pipeline_doubled (param $self i32) (result i32)
    local.get $self
    i32.load ;; .items
    i32.const 0 ;; missing argument
    call $List_each
    return
  )
)
```

----- RUN LOG -----
```logs
```
