----- SOURCE CODE -- main.bp
```botopink
val hash = comptime { break 6364 + 11; };
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
-module(main).
-export([main/1]).

main(_) ->
    Values = [
        #{<<"id">> => <<"ct_0">>, <<"value">> => (6364 + 11)}
    ],
    Json = json:encode(Values),
    io:format("~s~n", [Json]).

```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val hash = comptime {
    break 6364 + 11;
};
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "return_type": "void"
    }
  ]
}
```

