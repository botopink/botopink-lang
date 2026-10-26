-module(bp_load_cases_optional_chain_field_after_call@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__p'/1]).

%%% Decision 330 — a field read written after a `?.` link continues the

%%% chain, as a method there does (`find(0)?.str().length()`) and as

%%% TypeScript's does: `p(true)?.me().x` reads `x` off the record `me()`

%%% answers when `p(true)` is present, and is absent when it is not, so `??`

%%% takes its default; the receiver is evaluated once, on every target. A

%%% field after a field link (`p(true)?.inner.x`) and a method after the read

%%% (`p(true)?.me().name.length()`) continue it alike.

%% type Point: x, name, inner

%% type Inner: x

p(Present) ->
    '__bp_print'([<<"p">>]),
    case Present of
        true ->
            {bp_load_cases_optional_chain_field_after_call@main@@Point, 7, <<"seven">>, {bp_load_cases_optional_chain_field_after_call@main@@Inner, 3}};
        _ ->
            undefined
    end.

main() ->
    '__bp_print'([case case (fun(undefined) -> undefined; (Bp__chain0) -> bp_load_cases_optional_chain_field_after_call@main@@Point:me(Bp__chain0) end)(p(true)) of
        undefined ->
            undefined;
        __bp_optf_26_25 ->
            erlang:element(2, __bp_optf_26_25)
    end of
        undefined ->
            (-1);
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([case case (fun(undefined) -> undefined; (Bp__chain1) -> bp_load_cases_optional_chain_field_after_call@main@@Point:me(Bp__chain1) end)(p(false)) of
        undefined ->
            undefined;
        __bp_optf_27_26 ->
            erlang:element(2, __bp_optf_27_26)
    end of
        undefined ->
            (-1);
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([case case (fun(undefined) -> undefined; (_Opt2) -> erlang:element(4, _Opt2) end)(p(true)) of
        undefined ->
            undefined;
        __bp_optf_28_26 ->
            erlang:element(2, __bp_optf_28_26)
    end of
        undefined ->
            (-1);
        __bp_nullish@2 ->
            __bp_nullish@2
    end]),
    '__bp_print'([case case (fun(undefined) -> undefined; (_Opt3) -> erlang:element(4, _Opt3) end)(p(false)) of
        undefined ->
            undefined;
        __bp_optf_29_27 ->
            erlang:element(2, __bp_optf_29_27)
    end of
        undefined ->
            (-1);
        __bp_nullish@3 ->
            __bp_nullish@3
    end]),
    '__bp_print'([case '__bp_prim_length'(case (fun(undefined) -> undefined; (Bp__chain4) -> bp_load_cases_optional_chain_field_after_call@main@@Point:me(Bp__chain4) end)(p(true)) of
        undefined ->
            undefined;
        __bp_optf_30_25 ->
            erlang:element(3, __bp_optf_30_25)
    end) of
        undefined ->
            (-1);
        __bp_nullish@4 ->
            __bp_nullish@4
    end]),
    '__bp_print'([case case (fun(undefined) -> undefined; (Bp__chain5) -> bp_load_cases_optional_chain_field_after_call@main@@Point:me(Bp__chain5) end)(p(false)) of
        undefined ->
            undefined;
        __bp_optf_31_26 ->
            erlang:element(3, __bp_optf_31_26)
    end of
        undefined ->
            <<"none">>;
        __bp_nullish@5 ->
            __bp_nullish@5
    end]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/optional_chain_field_after_call|*">>.

'__bp_prim_length'(Recv) when erlang:is_list(Recv) ->
    erlang:length(Recv);
'__bp_prim_length'(Recv) when erlang:is_binary(Recv) ->
    erlang:length(unicode:characters_to_list(Recv));
'__bp_prim_length'(Recv) ->
    erlang:error({bp_unsupported_method, <<"length">>, 0, Recv}).

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

'__bp_priv__p'(A0) -> p(A0).
