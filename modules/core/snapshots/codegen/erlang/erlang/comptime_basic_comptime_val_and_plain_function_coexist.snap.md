----- SOURCE CODE -- main.bp
```botopink
val x = comptime 1 + 2;

fn double(n: i32) -> i32 {
    return n * 2;
}

fn main() {
    val r = double(21);
}
```

----- COMPTIME ERLANG -- main.erl
```erlang
-module(main).
-export([main/1]).

main(_) ->
    Values = [
        #{<<"id">> => <<"ct_0">>, <<"value">> => (1 + 2)}
    ],
    Json = json:encode(Values),
    io:format("~s~n", [Json]).
```

----- ERLANG -- main.erl
```erlang
-module(main).

x() ->
    3.

double(N) ->
    (N * 2).

main() ->
    R = double(21).
```
