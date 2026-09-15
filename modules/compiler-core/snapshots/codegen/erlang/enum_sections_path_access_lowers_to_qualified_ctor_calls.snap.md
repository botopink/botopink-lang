----- SOURCE CODE -- main.bp
```botopink
enum Token {
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

%% enum __Token__Color
%%   Red(_inner)

%% enum __Token__Color__Red
%%   __100
%%   __500

%% enum Token
%%   Color(_inner)

red500() ->
    {'Color', {'Red', '__500'}}.
```

----- RUN LOG -----
```logs
```
