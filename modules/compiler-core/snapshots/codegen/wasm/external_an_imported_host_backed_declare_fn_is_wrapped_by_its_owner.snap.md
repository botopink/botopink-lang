----- SOURCE CODE -- hostlib.bp
```botopink
#[@External.Node("String($0)"),
  @External.Erlang("""iolist_to_binary(io_lib:format("~0tp", [$0]))""")]
pub declare fn hostKey(v: i32) -> string;

#[@External.Node("$0.length"),
  @External.Erlang("erlang", "length")]
pub declare fn hostLen(xs: Array<string>) -> i32;

#[@External.Node("console.log($0)")]
pub declare fn nodeOnly(s: string) -> void;
```

----- WASM TEXT -- hostlib.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; declare fn hostKey — no wasm implementation (host-backed)
  ;; declare fn hostLen — no wasm implementation (host-backed)
  ;; declare fn nodeOnly — no wasm implementation (host-backed)
)
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import { hostKey, hostLen, nodeOnly };

pub fn main() {
    @print(hostKey(42));
    @print(hostLen(["a", "b"]));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `hostKey` has no `#[@External.<Target>(…)]` for the wasm backend
  ┌─ :4:12
  │
4 │     @print(hostKey(42));
  │            ^
```

