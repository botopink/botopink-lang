----- SOURCE CODE -- main.bp
```botopink
enum Token {
    Color {
        Red { 100, 500 }
        Hex(value: string),
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% enum __Token__Color
%%   Hex(value)
%%   Red(_inner)

%% enum __Token__Color__Red
%%   __100
%%   __500

%% enum Token
%%   Color(_inner)
```

----- RUN LOG -----
```logs
```
