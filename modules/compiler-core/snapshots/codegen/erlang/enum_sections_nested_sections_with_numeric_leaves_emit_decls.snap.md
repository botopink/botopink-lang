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

----- RUN LOG -----
```logs
```
