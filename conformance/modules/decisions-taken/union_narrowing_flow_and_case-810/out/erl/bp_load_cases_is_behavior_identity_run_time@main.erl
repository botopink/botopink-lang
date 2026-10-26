-module(bp_load_cases_is_behavior_identity_run_time@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__kind'/1, '__bp_priv__label'/1, '__bp_priv__say'/1]).

%%% Decision 810 (1) — at run time `is` tests a type's identity alone: a

%%% record's, and a behavior's (a record's or an enum's type implements it) — the value's type implements it — and a

%%% function type by its arity, on every target. A behavior type pattern

%%% (`Shown<unknown> { k -> … }`) is the same test. erlang and beam answered

%%% `false` for every behavior, commonJS named a class no module emits, wasm

%%% refused the test.

%% behavior Shown

%% type Tag: value

%% type Box: item

%% type Mark
%%   Plain
%%   Named(text)

kind(V) ->
    A = case '__bp_implements'(V, bp_load_cases_is_behavior_identity_run_time@main@@Shown) of
        true ->
            <<"shown">>;
        false ->
            <<"-">>
    end,
    B = case ((erlang:is_tuple(V) andalso (erlang:tuple_size(V) =:= 2)) andalso (erlang:element(1, V) =:= bp_load_cases_is_behavior_identity_run_time@main@@Box)) of
        true ->
            <<"box">>;
        false ->
            <<"-">>
    end,
    C = case erlang:is_function(V, 1) of
        true ->
            <<"fn">>;
        false ->
            <<"-">>
    end,
    <<('__bp_text'(A))/binary, " ", ('__bp_text'(B))/binary, " ", ('__bp_text'(C))/binary>>.

label(V) ->
    case V of
        __bp_case_40_9 ->
            case '__bp_implements'(__bp_case_40_9, bp_load_cases_is_behavior_identity_run_time@main@@Shown) of
                true ->
                    K = __bp_case_40_9,
                    <<"shown">>;
                false ->
                    case __bp_case_40_9 of
                        B = Box when ((erlang:is_tuple(Box) andalso (erlang:tuple_size(Box) =:= 2)) andalso (erlang:element(1, Box) =:= bp_load_cases_is_behavior_identity_run_time@main@@Box)) ->
                            <<"box">>;
                        _ ->
                            <<"other">>
                    end
            end
    end.

say(N) ->
    erlang:integer_to_binary(N).

main() ->
    '__bp_print'([kind({bp_load_cases_is_behavior_identity_run_time@main@@Tag, 1})]),
    '__bp_print'([kind({bp_load_cases_is_behavior_identity_run_time@main@@Box, 1})]),
    '__bp_print'([kind(fun say/1)]),
    '__bp_print'([kind(3)]),
    '__bp_print'([kind(bp_load_cases_is_behavior_identity_run_time@main@@Mark__v__plain), kind({bp_load_cases_is_behavior_identity_run_time@main@@Mark__v__named, <<"n">>})]),
    '__bp_print'([label({bp_load_cases_is_behavior_identity_run_time@main@@Tag, <<"t">>}), label({bp_load_cases_is_behavior_identity_run_time@main@@Box, <<"b">>}), label(fun say/1)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/is_behavior_identity_run_time|*">>.

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

'__bp_implements'(__BpA0, __BpA1) ->
    T = case erlang:is_tuple(__BpA0) andalso (erlang:tuple_size(__BpA0) > 0) of
true -> erlang:element(1, __BpA0);
false -> __BpA0
end,
case erlang:is_atom(T) andalso (T =/= true) andalso (T =/= false) andalso (T =/= undefined) of
true ->
M = case string:split(erlang:atom_to_list(T), "__v__") of
[P, _] -> erlang:list_to_atom(P);
_ -> T
end,
(code:ensure_loaded(M) =:= {module, M}) andalso erlang:function_exported(M, '__bp_behaviors', 0) andalso lists:member(__BpA1, erlang:apply(M, '__bp_behaviors', []));
false -> false
end.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__kind'(A0) -> kind(A0).

'__bp_priv__label'(A0) -> label(A0).

'__bp_priv__say'(A0) -> say(A0).
