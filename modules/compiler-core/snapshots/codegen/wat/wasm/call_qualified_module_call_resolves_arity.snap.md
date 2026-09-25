----- SOURCE CODE -- main.bp
```botopink
type List(tag: i32) {
    fn map(items: i32[], f: fn(item: i32) -> i32) -> i32[] {
        return items.map(f);
    }
}
type Pipeline(
    items: i32[]) {
    fn run(self: Self, f: fn(item: i32) -> i32) -> i32[] {
        return List.map(self.items, f);
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $List_map (param $items i32) (param $f i32) (result i32)
    unreachable ;; map needs a literal lambda on wasm (no function values)
    return
  )
  (func $Pipeline_run (param $self i32) (param $f i32) (result i32)
    local.get $self
    i32.load ;; .items
    local.get $f
    call $List_map
    return
  )
)
```

----- RUN LOG -----
```logs
```
