----- SOURCE CODE -- main.bp
```botopink
val Account = struct {
    _balance: number = 0,
    get balance(self: Self) -> number {
        return self._balance;
    }
    set balance(self: Self, value: number) {
        self._balance = value;
    }
    fn deposit(self: Self, amount: number) {
        self._balance += amount;
    }
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "struct_def",
      "name": "Account",
      "id": 0,
      "fields": {
        "_balance": "number"
      }
    }
  ]
}
```

