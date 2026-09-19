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

----- RUN LOG -----
```logs
```
