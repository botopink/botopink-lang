----- SOURCE CODE -- main.bp
```botopink
type Token {
    Color {
        Red { 100, 500 }
    }
}
fn red500() -> Token {
    return .Color.Red.500;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type __Token__Color
%%   Red(_inner)

%% type __Token__Color__Red
%%   __100
%%   __500

%% type Token
%%   Color(_inner)

red500() ->
    {test@main@@Token__v__color, {test@main@@__Token__Color__v__red, test@main@@__Token__Color__Red__v__500}}.
```

----- ERLANG -- test@main@@__Token__Color.erl
```erlang
-module(test@main@@__Token__Color).
-export(['__bp_format'/1]).

'__bp_format'({test@main@@__Token__Color__v__red, F0}) -> {variant, "__Token__Color.Red", [{"_inner", F0}]}.
```

----- ERLANG -- test@main@@__Token__Color__Red.erl
```erlang
-module(test@main@@__Token__Color__Red).
-export(['__bp_format'/1]).

'__bp_format'(test@main@@__Token__Color__Red__v__100) -> {variant, "__Token__Color__Red.__100", []};
'__bp_format'(test@main@@__Token__Color__Red__v__500) -> {variant, "__Token__Color__Red.__500", []}.
```

----- ERLANG -- test@main@@Token.erl
```erlang
-module(test@main@@Token).
-export(['__bp_format'/1]).

'__bp_format'({test@main@@Token__v__color, F0}) -> {variant, "Token.Color", [{"_inner", F0}]}.
```

----- RUN LOG -----
```logs
```
