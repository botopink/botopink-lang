----- SOURCE CODE -- main.bp
```botopink
fn firstOver(arr: i32[], limit: i32) -> i32 {
    var i = 0;
    val found = #[@generator] loop {
        if (i >= arr.length) { break 0; };
        val x = arr[i] ?? 0;
        i = i + 1;
        if (x > limit) { break x; };
    };
    var out = 0;
    for (found) { v -> out = v; };
    return out;
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "firstOver",
      "is_pub": false,
      "params": [
        {
          "name": "arr",
          "type": "i32[]"
        },
        {
          "name": "limit",
          "type": "i32"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "var i = 0;"
        },
        {
          "source": "val found = #[@generator] loop {"
        },
        {
          "source": "var out = 0;"
        },
        {
          "source": "for (found) { v -> out = v; };"
        },
        {
          "source": "return out;"
        }
      ]
    }
  ]
}
```

