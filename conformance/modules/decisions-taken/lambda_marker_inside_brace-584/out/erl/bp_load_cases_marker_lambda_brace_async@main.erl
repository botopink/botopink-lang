-module(bp_load_cases_marker_lambda_brace_async@main).
-compile({no_auto_import,[apply/2]}).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__double'/1, '__bp_priv__apply'/2, '__bp_priv__later'/1]).

%%% Decision 584 (1) — a lambda's marker is written inside the brace, before

%%% the parameters: `{ async x -> … }` is a lambda whose body may `await`,

%%% typed by the function type it is written for (147) — an annotated `val`,

%%% an argument, and the trailing form, `apply(6) { async x -> … }`; with no

%%% parameter it is `{ async -> … }`. The body answers its last expression.

%% @Async — eager lowering
double(X) ->
    '__bp_int'((X * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:10:14">>).

%% @Async — eager lowering
apply(V, F) ->
    F(V).

%% @Async — eager lowering
later(F) ->
    F().

%% @Async — eager lowering
main() ->
    G = fun(X) ->
        (fun() ->
            '__bp_int'((double(X) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:22:68">>)
        end)()
    end,
    '__bp_print'([G(4)]),
    '__bp_print'([apply(5, fun(X) ->
        (fun() ->
            double(X)
        end)()
    end)]),
    R = apply(6, fun(X) ->
        (fun() ->
            D = double(X),
            '__bp_int'((D + 100), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:29:11">>)
        end)()
    end),
    '__bp_print'([R]),
    S = later(fun() ->
        (fun() ->
            <<"no parameter">>
        end)()
    end),
    '__bp_print'([S]).

%% @Async — eager lowering
'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

%% @Async — eager lowering
'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/marker_lambda_brace_async|*">>.

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

'__bp_priv__double'(A0) -> double(A0).

'__bp_priv__apply'(A0, A1) -> apply(A0, A1).

'__bp_priv__later'(A0) -> later(A0).
