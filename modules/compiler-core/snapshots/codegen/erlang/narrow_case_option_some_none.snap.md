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
        {'Some', V} ->
            <<"value: ", ('__bp_text'(V))/binary>>
    end.

main() ->
    '__bp_print'([describe({'Some', 42})]),
    '__bp_print'([describe('None')]).

'__bp_text'(Value) when is_binary(Value) -> Value;
'__bp_text'(Value) -> iolist_to_binary(io_lib:format(<<"~p">>, [Value])).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
value: 42
empty
```
