----- SOURCE CODE -- main.bp
```botopink
type Token {
    Text {
        Bold, Italic, Underline,
    }
    Hover(inner: i32),
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type __Token__Text
%%   Bold
%%   Italic
%%   Underline

%% type Token
%%   Hover(inner)
%%   Text(_inner)
```

----- ERLANG -- test@main@@__Token__Text.erl
```erlang
-module(test@main@@__Token__Text).
-export(['__bp_format'/1]).

'__bp_format'(test@main@@__Token__Text__v__bold) -> {variant, "__Token__Text.Bold", []};
'__bp_format'(test@main@@__Token__Text__v__italic) -> {variant, "__Token__Text.Italic", []};
'__bp_format'(test@main@@__Token__Text__v__underline) -> {variant, "__Token__Text.Underline", []}.
```

----- ERLANG -- test@main@@Token.erl
```erlang
-module(test@main@@Token).
-export(['__bp_format'/1]).

'__bp_format'({test@main@@Token__v__hover, F0}) -> {variant, "Token.Hover", [{"inner", F0}]};
'__bp_format'({test@main@@Token__v__text, F0}) -> {variant, "Token.Text", [{"_inner", F0}]}.
```

----- RUN LOG -----
```logs
```
