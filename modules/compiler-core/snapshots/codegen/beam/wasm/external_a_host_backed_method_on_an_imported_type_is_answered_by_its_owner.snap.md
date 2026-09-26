----- SOURCE CODE -- hostlib.bp
```botopink
pub type Meter(base: i32) {
    #[@External.Node("""($0.base + $1)"""),
      @External.Erlang("""(element(2, $0) + $1)""")]
    pub declare fn plus(self: Self, n: i32) -> i32;
}
```

----- WASM TEXT -- hostlib.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
)
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import { Meter };

pub fn main() {
    @print(Meter(base: 40).plus(2));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `Meter.plus` has no `#[@External.<Target>(…)]` for the wasm backend
  ┌─ :4:28
  │
4 │     @print(Meter(base: 40).plus(2));
  │                            ^
```

