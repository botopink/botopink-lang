----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn parse(n: i32) -> @Result<string, string> {
    if (n < 0) { throw "negative"; };
    return "ok";
}
fn handle(n: i32) -> string {
    val r = parse(n);
    return case r {
        Ok(v) -> "parsed: " + v;
        Err(e) -> "error: " + e;
    };
}
fn main() {
    @print(handle(5));
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "parse",
      "is_pub": false,
      "params": [
        {
          "name": "n",
          "type": "i32"
        }
      ],
      "return_type": "Result<string,string>",
      "body": [
        {
          "source": "if (n < 0) { throw \"negative\"; };"
        },
        {
          "source": "return \"ok\";"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "handle",
      "is_pub": false,
      "params": [
        {
          "name": "n",
          "type": "i32"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "val r = parse(n);"
        },
        {
          "source": "return case r {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "@print(handle(5));"
        }
      ]
    }
  ]
}
```

