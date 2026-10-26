-module(bp_load_cases_optional_chain_record_fields@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__user'/1]).

%%% Decision 330 — `?.` along a chain of record fields, each one optional:

%%% the chain is absent at the first absent link, whichever it is, and a

%%% member or a method after a `?.` link runs only on a present value, on

%%% every target.

%% type Street: name

%% type Address: street, zip

%% type User: name, address

user(K) ->
    case (K =:= 0) of
        true ->
            undefined;
        _ ->
            case (K =:= 1) of
                true ->
                    {bp_load_cases_optional_chain_record_fields@main@@User, <<"ann">>, undefined};
                _ ->
                    case (K =:= 2) of
                        true ->
                            {bp_load_cases_optional_chain_record_fields@main@@User, <<"bo">>, {bp_load_cases_optional_chain_record_fields@main@@Address, undefined, <<"01">>}};
                        _ ->
                            {bp_load_cases_optional_chain_record_fields@main@@User, <<"cy">>, {bp_load_cases_optional_chain_record_fields@main@@Address, {bp_load_cases_optional_chain_record_fields@main@@Street, <<"Main">>}, <<"002">>}}
                    end
            end
    end.

main() ->
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt0) -> erlang:element(2, _Opt0) end)((fun(undefined) -> undefined; (_Opt1) -> erlang:element(2, _Opt1) end)((fun(undefined) -> undefined; (_Opt2) -> erlang:element(3, _Opt2) end)(user(3)))) of
        undefined ->
            <<"none">>;
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt3) -> erlang:element(2, _Opt3) end)((fun(undefined) -> undefined; (_Opt4) -> erlang:element(2, _Opt4) end)((fun(undefined) -> undefined; (_Opt5) -> erlang:element(3, _Opt5) end)(user(2)))) of
        undefined ->
            <<"none">>;
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt6) -> erlang:element(2, _Opt6) end)((fun(undefined) -> undefined; (_Opt7) -> erlang:element(2, _Opt7) end)((fun(undefined) -> undefined; (_Opt8) -> erlang:element(3, _Opt8) end)(user(1)))) of
        undefined ->
            <<"none">>;
        __bp_nullish@2 ->
            __bp_nullish@2
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt9) -> erlang:element(2, _Opt9) end)((fun(undefined) -> undefined; (_Opt10) -> erlang:element(2, _Opt10) end)((fun(undefined) -> undefined; (_Opt11) -> erlang:element(3, _Opt11) end)(user(0)))) of
        undefined ->
            <<"none">>;
        __bp_nullish@3 ->
            __bp_nullish@3
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain12) -> '__bp_prim_length'(Bp__chain12) end)((fun(undefined) -> undefined; (_Opt13) -> erlang:element(2, _Opt13) end)((fun(undefined) -> undefined; (_Opt14) -> erlang:element(2, _Opt14) end)((fun(undefined) -> undefined; (_Opt15) -> erlang:element(3, _Opt15) end)(user(3))))) of
        undefined ->
            (-1);
        __bp_nullish@4 ->
            __bp_nullish@4
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain16) -> '__bp_prim_length'(Bp__chain16) end)((fun(undefined) -> undefined; (_Opt17) -> erlang:element(2, _Opt17) end)((fun(undefined) -> undefined; (_Opt18) -> erlang:element(2, _Opt18) end)((fun(undefined) -> undefined; (_Opt19) -> erlang:element(3, _Opt19) end)(user(2))))) of
        undefined ->
            (-1);
        __bp_nullish@5 ->
            __bp_nullish@5
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain20) -> '__bp_prim_length'(Bp__chain20) end)((fun(undefined) -> undefined; (_Opt21) -> erlang:element(2, _Opt21) end)((fun(undefined) -> undefined; (_Opt22) -> erlang:element(2, _Opt22) end)((fun(undefined) -> undefined; (_Opt23) -> erlang:element(3, _Opt23) end)(user(0))))) of
        undefined ->
            (-1);
        __bp_nullish@6 ->
            __bp_nullish@6
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain24) -> '__bp_prim_length'(Bp__chain24) end)((fun(undefined) -> undefined; (_Opt25) -> erlang:element(3, _Opt25) end)((fun(undefined) -> undefined; (_Opt26) -> erlang:element(3, _Opt26) end)(user(2)))) of
        undefined ->
            (-1);
        __bp_nullish@7 ->
            __bp_nullish@7
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain27) -> '__bp_prim_length'(Bp__chain27) end)((fun(undefined) -> undefined; (_Opt28) -> erlang:element(3, _Opt28) end)((fun(undefined) -> undefined; (_Opt29) -> erlang:element(3, _Opt29) end)(user(1)))) of
        undefined ->
            (-1);
        __bp_nullish@8 ->
            __bp_nullish@8
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain30) -> '__bp_prim_toUpper'(Bp__chain30) end)((fun(undefined) -> undefined; (_Opt31) -> erlang:element(2, _Opt31) end)(user(3))) of
        undefined ->
            <<"none">>;
        __bp_nullish@9 ->
            __bp_nullish@9
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain32) -> '__bp_prim_toUpper'(Bp__chain32) end)((fun(undefined) -> undefined; (_Opt33) -> erlang:element(2, _Opt33) end)(user(0))) of
        undefined ->
            <<"none">>;
        __bp_nullish@10 ->
            __bp_nullish@10
    end]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/optional_chain_record_fields|*">>.

'__bp_prim_length'(Recv) when erlang:is_list(Recv) ->
    erlang:length(Recv);
'__bp_prim_length'(Recv) when erlang:is_binary(Recv) ->
    erlang:length(unicode:characters_to_list(Recv));
'__bp_prim_length'(Recv) ->
    erlang:error({bp_unsupported_method, <<"length">>, 0, Recv}).

'__bp_prim_toUpper'(Recv) when erlang:is_binary(Recv) ->
    string:uppercase(Recv);
'__bp_prim_toUpper'(Recv) ->
    erlang:error({bp_unsupported_method, <<"toUpper">>, 0, Recv}).

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

'__bp_priv__user'(A0) -> user(A0).
