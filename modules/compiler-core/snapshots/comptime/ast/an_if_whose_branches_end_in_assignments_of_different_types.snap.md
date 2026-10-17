----- SOURCE CODE -- main.bp
```botopink
fn takeWhile(items: i32[], pred: fn(item: i32) -> bool) -> i32[] {
    var out: Array<i32> = [];
    var taking = true;
    items.forEach({ x ->
        if (taking) {
            if (pred(x)) { out = out.append([x]); } else { taking = false; };
        };
    });
    return out;
}
fn main() {
    @print(takeWhile([1, 2, 3], { n -> return n < 3; }).length());
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "takeWhile",
      "is_pub": false,
      "params": [
        {
          "name": "items",
          "type": "i32[]"
        },
        {
          "name": "pred",
          "type": "fn(i32) -> bool"
        }
      ],
      "return_type": "i32[]",
      "body": [
        {
          "source": "var out: Array<i32> = [];"
        },
        {
          "source": "var taking = true;"
        },
        {
          "source": "items.forEach({ x ->"
        },
        {
          "source": "return out;"
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
          "source": "@print(takeWhile([1, 2, 3], { n -> return n < 3; }).length());"
        }
      ]
    }
  ]
}
```

