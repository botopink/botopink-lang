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
-module(main).

%% type __Token__Color
%%   Red(_inner)

%% type __Token__Color__Red
%%   __100
%%   __500

%% type Token
%%   Color(_inner)

red500() ->
    {'Color', {'Red', '__500'}}.
```

----- RUN LOG -----
```logs
```
