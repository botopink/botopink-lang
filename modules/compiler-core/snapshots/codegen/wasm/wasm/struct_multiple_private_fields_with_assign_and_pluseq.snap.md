----- SOURCE CODE -- main.bp
```botopink
val BankAccount = struct {
    _balance: f64 = 0.0,
    _owner: string = "",
    fn deposit(self: Self, amount: f64) {
        self._balance += amount;
    }
    fn setOwner(self: Self, name: string) {
        self._owner = name;
    }
    get balance(self: Self) -> f64 {
        return self._balance;
    }
    get owner(self: Self) -> string {
        return self._owner;
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $BankAccount_deposit (param $self i32) (param $amount i32)
    (local $__mem0 i32)
    local.get $self
    local.set $__mem0
    local.get $__mem0
    local.get $__mem0
    i32.load
    local.get $amount
    i32.add
    i32.store ;; ._balance +=
  )
  (func $BankAccount_setOwner (param $self i32) (param $name i32)
    local.get $self
    local.get $name
    i32.store offset=4 ;; ._owner =
  )
)
```

----- RUN LOG -----
```logs
```
