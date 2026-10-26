-module(bp_load_cases_optional_enum_method_absent_receiver@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__find'/1]).

%%% Decision 330 — `x?.m()` where `m` is a method of an enum and `x` is

%%% absent: the method is not called and the whole call is absent, so `??`

%%% takes its default; `x` is evaluated once, on every target

%%% (`modules/optional_enum_method_call` is the present receiver).

%% type Val
%%   Num(n)
%%   Text(s)

find(Kind) ->
    '__bp_print'([<<"find">>]),
    case (Kind =:= 1) of
        true ->
            {bp_load_cases_optional_enum_method_absent_receiver@main@@Val__v__text, <<"a">>};
        _ ->
            case (Kind =:= 2) of
                true ->
                    {bp_load_cases_optional_enum_method_absent_receiver@main@@Val__v__num, 40};
                _ ->
                    undefined
            end
    end.

main() ->
    B = find(0),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain0) -> bp_load_cases_optional_enum_method_absent_receiver@main@@Val:str(Bp__chain0) end)(B) of
        undefined ->
            <<"none">>;
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain1) -> bp_load_cases_optional_enum_method_absent_receiver@main@@Val:plus(Bp__chain1, 2) end)(find(0)) of
        undefined ->
            (-1);
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain2) -> '__bp_prim_length'(Bp__chain2) end)((fun(undefined) -> undefined; (Bp__chain3) -> bp_load_cases_optional_enum_method_absent_receiver@main@@Val:str(Bp__chain3) end)(find(0))) of
        undefined ->
            (-2);
        __bp_nullish@2 ->
            __bp_nullish@2
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain4) -> bp_load_cases_optional_enum_method_absent_receiver@main@@Val:plus(Bp__chain4, 2) end)(find(2)) of
        undefined ->
            (-1);
        __bp_nullish@3 ->
            __bp_nullish@3
    end]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/optional_enum_method_absent_receiver|*">>.

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

'__bp_priv__find'(A0) -> find(A0).
