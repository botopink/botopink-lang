----- SOURCE CODE -- main.bp
```botopink
interface Printable {
    fn print(self: Self),
}
record Person { name: string }
val PersonPrintable = implement Printable for Person {
    fn print(self: Self) {
        return self.name;
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $Person_print (param $self i32) (result i32)
    i32.const 0 ;; field access .name
    return
  )
)
```

----- RUN LOG -----
```logs
```
