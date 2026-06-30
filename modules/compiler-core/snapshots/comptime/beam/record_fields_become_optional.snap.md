----- SOURCE CODE -- main.bp
```botopink
record Config { port: i32, host: string }
val PartialCfg = partial(Config);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Config",
      "id": 0,
      "fields": {
        "port": "i32",
        "host": "string"
      }
    },
    {
      "ast": "val",
      "indent": "PartialCfg",
      "return_type": "record { port: optional<i32>, host: optional<string> }"
    }
  ]
}
```

