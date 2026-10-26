-module(bp_load_cases_trailing_lambda_call@main).
-compile({no_auto_import,[apply/2]}).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__twice'/1, '__bp_priv__apply'/2, '__bp_priv__withBase'/2]).

%%% Decision 525 — a trailing lambda fills the last function-typed parameter of

%%% a call, a method's or a plain function's; with no parameter it is written

%%% `{ -> … }`.

%% type Box: base

twice(F) ->
    '__bp_int'((F() * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:20:16">>).

apply(X, F) ->
    F(X).

withBase(X, F) ->
    '__bp_int'((X + F()), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:28:14">>).

main() ->
    B = {bp_load_cases_trailing_lambda_call@main@@Box, 1},
    '__bp_print'([bp_load_cases_trailing_lambda_call@main@@Box:run(B, fun() ->
        10
    end)]),
    '__bp_print'([bp_load_cases_trailing_lambda_call@main@@Box:through(B, fun(M) ->
        '__bp_int'((M + 5), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:34:30">>)
    end)]),
    '__bp_print'([bp_load_cases_trailing_lambda_call@main@@Box:add(B, 2, fun() ->
        3
    end)]),
    '__bp_print'([twice(fun() ->
        4
    end)]),
    '__bp_print'([apply(3, fun(K) ->
        '__bp_int'((K * 3), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:37:29">>)
    end)]),
    '__bp_print'([withBase(5, fun() ->
        6
    end)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/trailing_lambda_call|*">>.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'__bp_priv__twice'(A0) -> twice(A0).

'__bp_priv__apply'(A0, A1) -> apply(A0, A1).

'__bp_priv__withBase'(A0, A1) -> withBase(A0, A1).
