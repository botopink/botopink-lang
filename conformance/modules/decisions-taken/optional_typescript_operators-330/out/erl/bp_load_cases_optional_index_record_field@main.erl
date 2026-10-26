-module(bp_load_cases_optional_index_record_field@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__fields'/1]).

%%% Decision 330 — `xs?.[i]` over an optional array of records answers the

%%% record, or nothing: a field read off it by `?.` or `!` finds the record's

%%% own slot, even when another record declares a field of the same name.

%% type Field: name, message

%% type Label: name, id

fields(K) ->
    case (K =:= 0) of
        true ->
            undefined;
        _ ->
            [{bp_load_cases_optional_index_record_field@main@@Field, <<"email">>, undefined}]
    end.

main() ->
    Some = fields(1),
    First = case Some of
        undefined ->
            undefined;
        __bp_opt_18_21 ->
            (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(__bp_opt_18_21, 0)
    end,
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt0) -> erlang:element(2, _Opt0) end)(First) of
        undefined ->
            <<"no field">>;
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([erlang:element(2, case First of
        undefined ->
            erlang:error({panic, <<"value is null \x{E2}\x{80}\x{94} first! at src/main.bp:20:11">>});
        __bp_opt_20_16 ->
            __bp_opt_20_16
    end)]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt1) -> erlang:element(3, _Opt1) end)(First) of
        undefined ->
            <<"no message">>;
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    None = fields(0),
    Missing = case None of
        undefined ->
            undefined;
        __bp_opt_23_23 ->
            (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(__bp_opt_23_23, 0)
    end,
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt2) -> erlang:element(2, _Opt2) end)(Missing) of
        undefined ->
            <<"no field">>;
        __bp_nullish@2 ->
            __bp_nullish@2
    end]),
    '__bp_print'([erlang:element(2, {bp_load_cases_optional_index_record_field@main@@Label, <<"tag">>, 1})]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/optional_index_record_field|*">>.

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'({ok, P}, _) -> ["Ok(", '__bp_show'(P, false), $)];
'__bp_show'({error, P}, _) -> ["Error(", '__bp_show'(P, false), $)];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__fields'(A0) -> fields(A0).
