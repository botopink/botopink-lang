----- SOURCE CODE -- main.bp
```botopink
type Status { Ok, Fail }
#[@result]
fn check(s: Status) -> @Result<i32, string> {
    return case s {
        Ok -> 1;
        Fail -> throw "failed";
    };
}
fn main() {
    @print(check(Status.Ok).isOk());
    @print(check(Status.Fail).isOk());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% type Status
%%   Ok
%%   Fail

check(S) ->
    {ok, case S of
        main__t__status__v__ok ->
            1;
        main__t__status__v__fail ->
            {error, <<"failed">>}
    end}.

main() ->
    '__bp_print'([(fun(R) -> case R of {ok, _} -> true; _ -> false end end)(check(main__t__status__v__ok))]),
    '__bp_print'([(fun(R) -> case R of {ok, _} -> true; _ -> false end end)(check(main__t__status__v__fail))]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) when is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(atom_to_list(A), "__v__") of [P, _] -> list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- ERLANG -- main__t__status.erl
```erlang
-module(main__t__status).
-export(['__bp_format'/1]).

'__bp_format'(main__t__status__v__ok) -> {variant, "Status.Ok", []};
'__bp_format'(main__t__status__v__fail) -> {variant, "Status.Fail", []}.
```

----- RUN LOG -----
```logs
true
true
```
