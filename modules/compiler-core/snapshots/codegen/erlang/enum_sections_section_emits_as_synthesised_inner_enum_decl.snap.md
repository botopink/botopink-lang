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
-module(main).

%% type __Token__Text
%%   Bold
%%   Italic
%%   Underline

%% type Token
%%   Hover(inner)
%%   Text(_inner)
```

----- ERLANG -- main__t__token_text.erl
```erlang
-module(main__t__token_text).
-export(['__bp_format'/1]).

'__bp_format'(main__t__token_text__v__bold) -> {variant, "__Token__Text.Bold", []};
'__bp_format'(main__t__token_text__v__italic) -> {variant, "__Token__Text.Italic", []};
'__bp_format'(main__t__token_text__v__underline) -> {variant, "__Token__Text.Underline", []}.
```

----- ERLANG -- main__t__token.erl
```erlang
-module(main__t__token).
-export(['__bp_format'/1]).

'__bp_format'({main__t__token__v__hover, F0}) -> {variant, "Token.Hover", [{"inner", F0}]};
'__bp_format'({main__t__token__v__text, F0}) -> {variant, "Token.Text", [{"_inner", F0}]}.
```

----- RUN LOG -----
```logs
```
