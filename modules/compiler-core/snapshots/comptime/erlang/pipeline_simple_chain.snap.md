----- SOURCE CODE -- main.bp
```botopink
fn double(x: i32) -> i32 { return x * 2; }
fn inc(x: i32) -> i32 { return x + 1; }
fn main() {
    val result = 1 |> double |> inc;
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "double",
      "is_pub": false,
      "params": [
        {
          "name": "x",
          "type": ""
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "fn double(x: i32) -> i32 { return x * 2; }"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "inc",
      "is_pub": false,
      "params": [
        {
          "name": "x",
          "type": ""
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "fn inc(x: i32) -> i32 { return x + 1; }"
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
          "source": "val result = 1 |> double |> inc;"
        }
      ]
    }
  ]
}
```

