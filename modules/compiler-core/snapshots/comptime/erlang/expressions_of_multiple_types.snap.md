----- SOURCE CODE -- main.bp
```botopink
val pi      = comptime 3.14 * 2.0;
val maxVal  = comptime 100 + 1;
val banner  = comptime "Hello, " + "World";
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
-module(main).
-export([main/1]).

main(_) ->
    Values = [
        #{<<"id">> => <<"ct_0">>, <<"value">> => (3.14 * 2.0)},
        #{<<"id">> => <<"ct_1">>, <<"value">> => (100 + 1)},
        #{<<"id">> => <<"ct_2">>, <<"value">> => ("Hello, " ++ "World")}
    ],
    Json = json:encode(Values),
    io:format("~s~n", [Json]).

```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val pi = 6.28;

val maxVal = 101;

val banner = "Hello, World";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "return_type": "f64"
    },
    {
      "ast": "val",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "return_type": "string"
    }
  ]
}
```

