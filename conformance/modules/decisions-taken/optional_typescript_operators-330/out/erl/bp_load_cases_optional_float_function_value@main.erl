-module(bp_load_cases_optional_float_function_value@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__halver'/1, '__bp_priv__shower'/1, '__bp_priv__quarter'/1, '__bp_priv__wide'/1]).

%%% Decision 330 — a function taking or answering a float (or an `i64`) is

%%% a value like any other: bound out of an optional (`if (h) { g -> … }`),

%%% called through `?.()`, held by a typed local, or a top-level function

%%% named as a value. The argument reaches it and its answer comes back

%%% unchanged, on every target.

halver(Present) ->
    F = fun(X) ->
        (X / 2.0)
    end,
    case Present of
        true ->
            F;
        false ->
            undefined
    end.

shower(Present) ->
    F = fun(X) ->
        <<"v=", ('__bp_text'(float_to_binary(X, [short])))/binary>>
    end,
    case Present of
        true ->
            F;
        false ->
            undefined
    end.

quarter(X) ->
    (X / 4.0).

wide(Present) ->
    F = fun(N) ->
        '__bp_int'((N * 2), -9223372036854775808, 9223372036854775807, <<"integer overflow: * on i64 at src/main.bp:24:38">>)
    end,
    case Present of
        true ->
            F;
        false ->
            undefined
    end.

main() ->
    H = halver(true),
    case H of
        undefined -> undefined;
        G ->
            '__bp_print'([G(3.0)])
    end,
    '__bp_print'([case case halver(true) of
        undefined ->
            undefined;
        __bp_opt_34_23 ->
            (__bp_opt_34_23)(3.0)
    end of
        undefined ->
            0.0;
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([case case halver(false) of
        undefined ->
            undefined;
        __bp_opt_35_24 ->
            (__bp_opt_35_24)(3.0)
    end of
        undefined ->
            (-1.0);
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([case case shower(true) of
        undefined ->
            undefined;
        __bp_opt_36_23 ->
            (__bp_opt_36_23)(1.5)
    end of
        undefined ->
            <<"none">>;
        __bp_nullish@2 ->
            __bp_nullish@2
    end]),
    '__bp_print'([case case shower(false) of
        undefined ->
            undefined;
        __bp_opt_37_24 ->
            (__bp_opt_37_24)(1.5)
    end of
        undefined ->
            <<"none">>;
        __bp_nullish@3 ->
            __bp_nullish@3
    end]),
    Q = fun quarter/1,
    '__bp_print'([Q(2.0)]),
    Local = fun(X) ->
        (X + 0.25)
    end,
    '__bp_print'([Local(1.0)]),
    '__bp_print'([case case wide(true) of
        undefined ->
            undefined;
        __bp_opt_42_21 ->
            (__bp_opt_42_21)(5000000000)
    end of
        undefined ->
            0;
        __bp_nullish@4 ->
            __bp_nullish@4
    end]),
    '__bp_print'([case case wide(false) of
        undefined ->
            undefined;
        __bp_opt_43_22 ->
            (__bp_opt_43_22)(5)
    end of
        undefined ->
            (-1);
        __bp_nullish@5 ->
            __bp_nullish@5
    end]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/optional_float_function_value|*">>.

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

'__bp_priv__halver'(A0) -> halver(A0).

'__bp_priv__shower'(A0) -> shower(A0).

'__bp_priv__quarter'(A0) -> quarter(A0).

'__bp_priv__wide'(A0) -> wide(A0).
