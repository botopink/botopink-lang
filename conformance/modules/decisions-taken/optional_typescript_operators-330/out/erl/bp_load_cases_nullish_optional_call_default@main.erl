-module(bp_load_cases_nullish_optional_call_default@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__primary'/1, '__bp_priv__backup'/1, '__bp_priv__greeter'/1, '__bp_priv__nickname'/1]).

%%% Decision 330 — the default of `??` may itself be a `?.()` call, defaulted

%%% again by a further `??`: `a ?? f?.(x) ?? d` takes the first present value,

%%% and a default is evaluated only when everything before it is absent, on

%%% every target.

primary(Present) ->
    F = fun(N) ->
        '__bp_int'((N + 10), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:9:38">>)
    end,
    case Present of
        true ->
            F;
        false ->
            undefined
    end.

backup(Present) ->
    '__bp_print'([<<"backup">>]),
    F = fun(N) ->
        '__bp_int'((N + 100), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:15:38">>)
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

nickname(Present) ->
    case Present of
        true ->
            <<"bo">>;
        false ->
            undefined
    end.

main() ->
    '__bp_print'([case case primary(true) of
        undefined ->
            undefined;
        __bp_opt_29_24 ->
            (__bp_opt_29_24)(1)
    end of
        undefined ->
            case case backup(true) of
                undefined ->
                    undefined;
                __bp_opt_29_45 ->
                    (__bp_opt_29_45)(1)
            end of
                undefined ->
                    (-1);
                __bp_nullish ->
                    __bp_nullish
            end;
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([case case primary(false) of
        undefined ->
            undefined;
        __bp_opt_30_25 ->
            (__bp_opt_30_25)(1)
    end of
        undefined ->
            case case backup(true) of
                undefined ->
                    undefined;
                __bp_opt_30_46 ->
                    (__bp_opt_30_46)(1)
            end of
                undefined ->
                    (-1);
                __bp_nullish@2 ->
                    __bp_nullish@2
            end;
        __bp_nullish@3 ->
            __bp_nullish@3
    end]),
    '__bp_print'([case case primary(false) of
        undefined ->
            undefined;
        __bp_opt_31_25 ->
            (__bp_opt_31_25)(1)
    end of
        undefined ->
            case case backup(false) of
                undefined ->
                    undefined;
                __bp_opt_31_47 ->
                    (__bp_opt_31_47)(1)
            end of
                undefined ->
                    (-1);
                __bp_nullish@4 ->
                    __bp_nullish@4
            end;
        __bp_nullish@5 ->
            __bp_nullish@5
    end]),
    '__bp_print'([case nickname(true) of
        undefined ->
            case case greeter(true) of
                undefined ->
                    undefined;
                __bp_opt_32_42 ->
                    (__bp_opt_32_42)(<<"you">>)
            end of
                undefined ->
                    <<"nobody">>;
                __bp_nullish@6 ->
                    __bp_nullish@6
            end;
        __bp_nullish@7 ->
            __bp_nullish@7
    end]),
    '__bp_print'([case nickname(false) of
        undefined ->
            case case greeter(true) of
                undefined ->
                    undefined;
                __bp_opt_33_43 ->
                    (__bp_opt_33_43)(<<"you">>)
            end of
                undefined ->
                    <<"nobody">>;
                __bp_nullish@8 ->
                    __bp_nullish@8
            end;
        __bp_nullish@9 ->
            __bp_nullish@9
    end]),
    '__bp_print'([case nickname(false) of
        undefined ->
            case case greeter(false) of
                undefined ->
                    undefined;
                __bp_opt_34_44 ->
                    (__bp_opt_34_44)(<<"you">>)
            end of
                undefined ->
                    <<"nobody">>;
                __bp_nullish@10 ->
                    __bp_nullish@10
            end;
        __bp_nullish@11 ->
            __bp_nullish@11
    end]),
    N = case nickname(false) of
        undefined ->
            case case greeter(true) of
                undefined ->
                    undefined;
                __bp_opt_35_45 ->
                    (__bp_opt_35_45)(<<"all">>)
            end of
                undefined ->
                    <<"">>;
                __bp_nullish@12 ->
                    __bp_nullish@12
            end;
        __bp_nullish@13 ->
            __bp_nullish@13
    end,
    '__bp_print'([erlang:length(unicode:characters_to_list(N))]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/nullish_optional_call_default|*">>.

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

'__bp_priv__primary'(A0) -> primary(A0).

'__bp_priv__backup'(A0) -> backup(A0).

'__bp_priv__greeter'(A0) -> greeter(A0).

'__bp_priv__nickname'(A0) -> nickname(A0).
