----- SOURCE CODE -- main.bp
```botopink
enum Token {
    Text {
        Bold, Italic, Underline,
    }
    Hover(inner: i32),
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% enum __Token__Text
%%   Bold
%%   Italic
%%   Underline

%% enum Token
%%   Hover(inner)
%%   Text(_inner)
```

----- RUN LOG -----
```logs
```
