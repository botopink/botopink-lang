----- SOURCE CODE -- main.bp
```botopink
val Container = interface <T> {
    fn fetch(self: Self) -> T;
    fn store(self: Self, value: T);
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "interface_def",
      "name": "Container",
      "generic": [
        "T"
      ]
    }
  ]
}
```

