----- SOURCE CODE -- main.bp
```botopink
#[@result]
#[@External.Erlang( """(fun(__S) -> try {ok, binary_to_integer(__S)} catch _:_ -> {error, <<"not a number">>} end end)($0)"""),
  @External.Node("""(() => { const __n = Number($0); return Number.isFinite(__n) ? { ok: __n } : { error: "not a number" } })()""")]
pub declare fn parseInt(s: string) -> @Result<i32, string>;

fn main() {
    val r = parseInt("42");
    @print(r.unwrapOr(-1));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% external fn parseInt (no erlang target)

main() ->
    R = (fun(__S) -> try {ok, binary_to_integer(__S)} catch _:_ -> {error, <<"not a number">>} end end)(<<"42">>),
    io:format("~p~n", [(fun(R) -> case R of {ok, V} -> V; _ -> ((-1)) end end)(R)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
42
```
