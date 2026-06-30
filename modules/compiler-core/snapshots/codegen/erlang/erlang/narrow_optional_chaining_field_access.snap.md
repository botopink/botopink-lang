----- SOURCE CODE -- main.bp
```botopink
val Inner = record { value: i32 }
val Outer = record { inner: ?Inner }
fn getValue(o: Outer) -> ?i32 {
    return o.inner?.value;
}
fn main() {
    val o = Outer(inner: Inner(value: 42));
    @print(getValue(o));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record Inner: value

%% record Outer: inner

getValue(O) ->
    (fun(undefined) -> undefined; (_Opt0) -> maps:get(value, _Opt0) end)(maps:get(inner, O)).

main() ->
    O = #{inner => #{value => 42}},
    io:format("~p~n", [getValue(O)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
42
```
