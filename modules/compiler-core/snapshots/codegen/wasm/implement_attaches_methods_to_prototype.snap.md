----- SOURCE CODE -- main.bp
```botopink
behavior Printable {
    fn print(self: Self) -> string;
}
type Person(name: string)
val PersonPrintable = implement Printable for Person {
    fn print(self: Self) -> string {
        return self.name;
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $Person_print (param $self i32) (result i32)
    local.get $self
    i32.load ;; .name
    return
  )
)
```

----- RUN LOG -----
```logs
```
