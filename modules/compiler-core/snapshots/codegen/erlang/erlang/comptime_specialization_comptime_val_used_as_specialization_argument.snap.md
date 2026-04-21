----- SOURCE CODE -- main.bp
```botopink
val base = comptime 10 + 5;

fn scale(comptime factor: i32, value: i32) -> i32 {
    return value * factor;
}

fn main() {
    val doubled = scale(2, base);
    val tripled = scale(3, base);
    val doubledAgain = scale(2, 100);
}
```

----- COMPTIME ERLANG -- main.erl
```erlang
-module(main).
-export([main/1]).

main(_) ->
    Values = [
        #{<<"id">> => <<"ct_0">>, <<"value">> => (10 + 5)}
    ],
    Json = json:encode(Values),
    io:format("~s~n", [Json]).
```

----- ERLANG -- main.erl
```erlang
-module(main).

base() ->
    15.

main() ->
    Doubled = scale_$0(Base),
    Tripled = scale_$1(Base),
    DoubledAgain = scale_$0(100).

scale_$0(Value) ->
    Factor = 2,
    (Value * Factor).

scale_$1(Value) ->
    Factor = 3,
    (Value * Factor).
```
