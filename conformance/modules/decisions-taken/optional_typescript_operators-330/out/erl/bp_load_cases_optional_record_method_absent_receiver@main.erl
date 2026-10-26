-module(bp_load_cases_optional_record_method_absent_receiver@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__p'/1, '__bp_priv__col'/1]).

%%% Decision 330 — `recv?.m()` over a method of a record or of an all-unit

%%% enum: the receiver is evaluated once, the method runs only on a present

%%% one, and the call is the optional of its answer — a present `0`, `false`

%%% stays present, a float answer too, an answer that is itself optional is

%%% not nested — on every target (`modules/optional_method_absent_receiver`

%%% is a primitive receiver, `modules/optional_enum_method_absent_receiver`

%%% an enum with payloads).

%% type P: x

%% type C
%%   Red
%%   Green

p(C) ->
    case C of
        true ->
            {bp_load_cases_optional_record_method_absent_receiver@main@@P, 0};
        false ->
            undefined
    end.

col(C) ->
    case (C =:= 0) of
        true ->
            undefined;
        _ ->
            case (C =:= 1) of
                true ->
                    bp_load_cases_optional_record_method_absent_receiver@main@@C__v__red;
                _ ->
                    bp_load_cases_optional_record_method_absent_receiver@main@@C__v__green
            end
    end.

main() ->
    '__bp_print'([(fun(undefined) -> undefined; (Bp__chain0) -> bp_load_cases_optional_record_method_absent_receiver@main@@P:twice(Bp__chain0) end)(p(true))]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain1) -> bp_load_cases_optional_record_method_absent_receiver@main@@P:half(Bp__chain1) end)(p(true)) of
        undefined ->
            (-1.0);
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain2) -> bp_load_cases_optional_record_method_absent_receiver@main@@P:half(Bp__chain2) end)(p(false)) of
        undefined ->
            (-1.0);
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain3) -> bp_load_cases_optional_record_method_absent_receiver@main@@P:zero(Bp__chain3) end)(p(true)) of
        undefined ->
            false;
        __bp_nullish@2 ->
            __bp_nullish@2
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain4) -> bp_load_cases_optional_record_method_absent_receiver@main@@P:zero(Bp__chain4) end)(p(false)) of
        undefined ->
            false;
        __bp_nullish@3 ->
            __bp_nullish@3
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain5) -> bp_load_cases_optional_record_method_absent_receiver@main@@P:'maybe'(Bp__chain5) end)(p(true)) of
        undefined ->
            (-1);
        __bp_nullish@4 ->
            __bp_nullish@4
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain6) -> bp_load_cases_optional_record_method_absent_receiver@main@@P:'maybe'(Bp__chain6) end)(p(false)) of
        undefined ->
            (-1);
        __bp_nullish@5 ->
            __bp_nullish@5
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt7) -> erlang:element(2, _Opt7) end)((fun(undefined) -> undefined; (Bp__chain8) -> bp_load_cases_optional_record_method_absent_receiver@main@@P:me(Bp__chain8) end)(p(true))) of
        undefined ->
            (-1);
        __bp_nullish@6 ->
            __bp_nullish@6
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt9) -> erlang:element(2, _Opt9) end)((fun(undefined) -> undefined; (Bp__chain10) -> bp_load_cases_optional_record_method_absent_receiver@main@@P:me(Bp__chain10) end)(p(false))) of
        undefined ->
            (-1);
        __bp_nullish@7 ->
            __bp_nullish@7
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain11) -> bp_load_cases_optional_record_method_absent_receiver@main@@C:n(Bp__chain11) end)(col(1)) of
        undefined ->
            (-1);
        __bp_nullish@8 ->
            __bp_nullish@8
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain12) -> bp_load_cases_optional_record_method_absent_receiver@main@@C:n(Bp__chain12) end)(col(2)) of
        undefined ->
            (-1);
        __bp_nullish@9 ->
            __bp_nullish@9
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain13) -> bp_load_cases_optional_record_method_absent_receiver@main@@C:n(Bp__chain13) end)(col(0)) of
        undefined ->
            (-1);
        __bp_nullish@10 ->
            __bp_nullish@10
    end]),
    Q = p(true),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain14) -> bp_load_cases_optional_record_method_absent_receiver@main@@P:twice(Bp__chain14) end)(Q) of
        undefined ->
            7;
        __bp_nullish@11 ->
            __bp_nullish@11
    end]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/optional_record_method_absent_receiver|*">>.

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

'__bp_priv__col'(A0) -> col(A0).
