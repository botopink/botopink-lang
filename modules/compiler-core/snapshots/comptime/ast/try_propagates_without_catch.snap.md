----- SOURCE CODE -- main.bp
```botopink
type IoError(path: string)
#[@result]
fn load() -> @Result<string, IoError> {
    throw IoError(path: "/data");
}
#[@result]
fn run() -> @Result<string, IoError> {
    val s = try load();
    return s;
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "IoError",
      "fields": {
        "path": "string"
      }
    },
    {
      "ast": "fn_def",
      "name": "load",
      "is_pub": false,
      "params": [],
      "return_type": "Result<string,IoError>",
      "body": [
        {
          "source": "throw IoError(path: \"/data\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "run",
      "is_pub": false,
      "params": [],
      "return_type": "Result<string,IoError>",
      "body": [
        {
          "source": "val s = try load();"
        },
        {
          "source": "return s;"
        }
      ]
    }
  ]
}
```

