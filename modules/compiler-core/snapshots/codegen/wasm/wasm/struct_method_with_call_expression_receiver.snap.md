----- SOURCE CODE -- main.bp
```botopink
val Logger = struct {
    _prefix: string = "",
    fn setPrefix(self: Self, p: string) {
        self._prefix = p;
    }
    fn log(self: Self, msg: string) {
        console.log(self._prefix, msg);
    }
    get prefix(self: Self) -> string {
        return self._prefix;
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $Logger_setPrefix (param $self i32) (param $p i32)
    local.get $self
    local.get $p
    i32.store ;; ._prefix =
  )
  (func $Logger_log (param $self i32) (param $msg i32) (result i32)
    local.get $self
    i32.load ;; ._prefix
    local.get $msg
    call $log
  )
)
```

----- RUN LOG -----
```logs
```
