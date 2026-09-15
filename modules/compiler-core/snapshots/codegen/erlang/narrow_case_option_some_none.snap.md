----- SOURCE CODE -- main.bp
```botopink
enum Opt { None, Some(value: i32) }
fn describe(opt: Opt) -> string {
    return case opt {
        None -> "empty";
        Some(v) -> "value: " + v;
    };
}
fn main() {
    @print(describe(Opt.Some(value: 42)));
    @print(describe(Opt.None));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% enum Opt
%%   None
%%   Some(value)

describe(Opt) ->
    case Opt of
        'None' ->
            <<"empty">>;
        {tag, Some, V} ->
            (<<"value: ">> + V)
    end.

main() ->
    io:format("~p~n", [describe({'Some', 42})]),
    io:format("~p~n", [describe('None')]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
