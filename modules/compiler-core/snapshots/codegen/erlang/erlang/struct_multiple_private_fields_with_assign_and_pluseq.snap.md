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

----- ERLANG -- main.erl
```erlang
-module(main).

-record(BankAccount, {_balance, _owner}).

deposit(Amount) ->
    %% field += not directly supported in Erlang.

setOwner(Name) ->
    %% self._owner = ....
```
