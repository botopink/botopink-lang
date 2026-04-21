----- SOURCE CODE -- main.bp
```botopink
fn add(a: i32, b: i32) -> i32 { return a + b; }
fn multiply(a: i32, b: i32) -> i32 { return a * b; }
fn format(value: i32, prefix: string, suffix: string) -> string { return prefix + value + suffix; }
fn main() {
    val result = 5 |> add(3) |> multiply(2) |> format("Result: ", " !");
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "add",
      "is_pub": false,
      "params": [
        {
          "name": "a",
          "type": ""
        },
        {
          "name": "b",
          "type": ""
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "fn add(a: i32, b: i32) -> i32 { return a + b; }"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "multiply",
      "is_pub": false,
      "params": [
        {
          "name": "a",
          "type": ""
        },
        {
          "name": "b",
          "type": ""
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "fn multiply(a: i32, b: i32) -> i32 { return a * b; }"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "format",
      "is_pub": false,
      "params": [
        {
          "name": "value",
          "type": ""
        },
        {
          "name": "prefix",
          "type": ""
        },
        {
          "name": "suffix",
          "type": ""
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "fn format(value: i32, prefix: string, suffix: string) -> string { return prefix + value + suffix; }"
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
          "source": "val result = 5 |> add(3) |> multiply(2) |> format(\"Result: \", \" !\");"
        }
      ]
    }
  ]
}
```

