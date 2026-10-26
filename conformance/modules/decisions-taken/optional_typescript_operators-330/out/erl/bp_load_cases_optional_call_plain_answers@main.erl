-module(bp_load_cases_optional_call_plain_answers@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__counter'/1, '__bp_priv__greeter'/1, '__bp_priv__checker'/1, '__bp_priv__maker'/1]).

%%% Decision 330 — `f?.(args)` over a function answering a plain value is

%%% that value's optional: absent when the optional holding the function is,

%%% the function's answer otherwise — a present `0` included — whatever the

%%% answer's type (an integer, a string, a bool, a record).

%% type Point: x, y

counter(Present) ->
    F = fun(N) ->
        '__bp_int'((N - 5), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/main.bp:11:38">>)
    end,
    case Present of
        true ->
            F;
        false ->
            undefined
    end.

greeter(Present) ->
    F = fun(S) ->
        <<"hi ", ('__bp_text'(S))/binary>>
    end,
    case Present of
        true ->
            F;
        false ->
            undefined
    end.

checker(Present) ->
    F = fun(N) ->
        (N =:= 0)
    end,
    case Present of
        true ->
            F;
        false ->
            undefined
    end.

maker(Present) ->
    F = fun(N) ->
        {bp_load_cases_optional_call_plain_answers@main@@Point, N, '__bp_int'((N * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:26:55">>)}
    end,
    case Present of
        true ->
            F;
        false ->
            undefined
    end.

main() ->
    '__bp_print'([case case counter(true) of
        undefined ->
            undefined;
        __bp_opt_31_24 ->
            (__bp_opt_31_24)(6)
    end of
        undefined ->
            (-1);
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([case case counter(true) of
        undefined ->
            undefined;
        __bp_opt_32_24 ->
            (__bp_opt_32_24)(5)
    end of
        undefined ->
            (-1);
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([case case counter(false) of
        undefined ->
            undefined;
        __bp_opt_33_25 ->
            (__bp_opt_33_25)(5)
    end of
        undefined ->
            (-1);
        __bp_nullish@2 ->
            __bp_nullish@2
    end]),
    '__bp_print'([case counter(true) of
        undefined ->
            undefined;
        __bp_opt_34_24 ->
            (__bp_opt_34_24)(5)
    end]),
    '__bp_print'([case counter(false) of
        undefined ->
            undefined;
        __bp_opt_35_25 ->
            (__bp_opt_35_25)(5)
    end]),
    '__bp_print'([case case greeter(true) of
        undefined ->
            undefined;
        __bp_opt_36_24 ->
            (__bp_opt_36_24)(<<"bo">>)
    end of
        undefined ->
            <<"nobody">>;
        __bp_nullish@3 ->
            __bp_nullish@3
    end]),
    '__bp_print'([case case greeter(false) of
        undefined ->
            undefined;
        __bp_opt_37_25 ->
            (__bp_opt_37_25)(<<"bo">>)
    end of
        undefined ->
            <<"nobody">>;
        __bp_nullish@4 ->
            __bp_nullish@4
    end]),
    '__bp_print'([case case checker(true) of
        undefined ->
            undefined;
        __bp_opt_38_24 ->
            (__bp_opt_38_24)(0)
    end of
        undefined ->
            false;
        __bp_nullish@5 ->
            __bp_nullish@5
    end]),
    '__bp_print'([case case checker(false) of
        undefined ->
            undefined;
        __bp_opt_39_25 ->
            (__bp_opt_39_25)(0)
    end of
        undefined ->
            true;
        __bp_nullish@6 ->
            __bp_nullish@6
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt0) -> erlang:element(3, _Opt0) end)(case maker(true) of
        undefined ->
            undefined;
        __bp_opt_40_22 ->
            (__bp_opt_40_22)(4)
    end) of
        undefined ->
            (-1);
        __bp_nullish@7 ->
            __bp_nullish@7
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt1) -> erlang:element(3, _Opt1) end)(case maker(false) of
        undefined ->
            undefined;
        __bp_opt_41_23 ->
            (__bp_opt_41_23)(4)
    end) of
        undefined ->
            (-1);
        __bp_nullish@8 ->
            __bp_nullish@8
    end]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/optional_call_plain_answers|*">>.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

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

'__bp_priv__counter'(A0) -> counter(A0).

'__bp_priv__greeter'(A0) -> greeter(A0).

'__bp_priv__checker'(A0) -> checker(A0).

'__bp_priv__maker'(A0) -> maker(A0).
