----- SOURCE CODE -- main.bp
```botopink
val Account = struct {
    _balance: i32 = 0,
    fn deposit(self: Self, amount: i32) {
        self._balance += amount;
    }
};
val a = Account(0);
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
        "_balance": "i32"
      }
    },
    {
      "ast": "val",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "i32"
          }
        ],
        "return_type": "Account"
      },
      "return_type": "Account"
    }
  ]
}
```

