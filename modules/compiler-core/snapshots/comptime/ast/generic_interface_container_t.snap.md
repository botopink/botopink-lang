----- SOURCE CODE -- main.bp
```botopink
val Container = behavior <T> {
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
      ],
      "methods": [
        {
          "name": "fetch",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "T"
        },
        {
          "name": "store",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "value",
              "type": "T"
            }
          ],
          "return_type": "void"
        }
      ]
    }
  ]
}
```

