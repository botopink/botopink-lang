----- SOURCE CODE -- main.bp
```botopink
type Config(port: i32, host: string)
val PartialCfg = partial(Config);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Config",
      "fields": {
        "port": "i32",
        "host": "string"
      }
    },
    {
      "ast": "val",
      "ident": "PartialCfg",
      "return_type": "record { port: ?i32, host: ?string }"
    }
  ]
}
```

