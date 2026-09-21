----- SOURCE CODE -- main.bp
```botopink
type Token {
    Color {
        Red { 100, 500 }
        Hex(value: string),
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type __Token__Color
%%   Hex(value)
%%   Red(_inner)

%% type __Token__Color__Red
%%   __100
%%   __500

%% type Token
%%   Color(_inner)
```

----- ERLANG -- main__t__token_color.erl
```erlang
-module(main__t__token_color).
-export(['__bp_format'/1]).

'__bp_format'({main__t__token_color__v__hex, F0}) -> {variant, "__Token__Color.Hex", [{"value", F0}]};
'__bp_format'({main__t__token_color__v__red, F0}) -> {variant, "__Token__Color.Red", [{"_inner", F0}]}.
```

----- ERLANG -- main__t__token_color_red.erl
```erlang
-module(main__t__token_color_red).
-export(['__bp_format'/1]).

'__bp_format'(main__t__token_color_red__v__100) -> {variant, "__Token__Color__Red.__100", []};
'__bp_format'(main__t__token_color_red__v__500) -> {variant, "__Token__Color__Red.__500", []}.
```

----- ERLANG -- main__t__token.erl
```erlang
-module(main__t__token).
-export(['__bp_format'/1]).

'__bp_format'({main__t__token__v__color, F0}) -> {variant, "Token.Color", [{"_inner", F0}]}.
```

----- RUN LOG -----
```logs
```
