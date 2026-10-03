----- SOURCE CODE -- main.bp
```botopink
fn locate() -> SourceLocation {
    return @src();
}
val loc = @src();
test "src: in a test" {
    val here = @src();
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "locate",
      "is_pub": false,
      "params": [],
      "return_type": "SourceLocation",
      "body": [
        {
          "source": "return @src();"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "loc",
      "return_type": "SourceLocation",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "file",
            "value": "string"
          },
          {
            "name": "line",
            "value": "i32"
          },
          {
            "name": "column",
            "value": "i32"
          },
          {
            "name": "fnName",
            "value": "string"
          }
        ],
        "return_type": "SourceLocation"
      }
    }
  ]
}
```

