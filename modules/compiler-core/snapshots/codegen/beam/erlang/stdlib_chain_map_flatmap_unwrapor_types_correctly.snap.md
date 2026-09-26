----- SOURCE CODE -- main.bp
```botopink
fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
fn validate(n: i32) -> @Result<i32, string> { @todo(); }
fn main() {
    val r = parseAge("42")
        .map({ n -> n + 1 })
        .flatMap({ n -> validate(n) })
        .unwrapOr(0);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

parseAge(S) ->
    erlang:error({todo, <<"not implemented">>}).

validate(N) ->
    erlang:error({todo, <<"not implemented">>}).

main() ->
    R = (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (0) end end)((fun(__BpR) -> case __BpR of {ok, __BpV1} -> (fun(N) ->
        validate(N)
    end)(__BpV1); _ -> __BpR end end)((fun(__BpR) -> case __BpR of {ok, __BpV2} -> {ok, (fun(N) ->
        (N + 1)
    end)(__BpV2)}; _ -> __BpR end end)(parseAge(<<"42">>)))).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
