-module(bp_load_cases_fn_expr_typed_in_record_field@main).
-compile({no_auto_import,[apply/2]}).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__apply'/2]).

%%% Decision 408 — the typed function expression is legal as a record field's

%%% value and an array element, checked against the field's `fn(x: i32) -> i32`;

%%% its tail (409) or its `return` is its answer, and a lambda beside it in the

%%% array takes its types from the element type.

%% type Op: name, run

apply(Op, V) ->
    (erlang:element(3, Op))(V).

main() ->
    Inc = {bp_load_cases_fn_expr_typed_in_record_field@main@@Op, <<"inc">>, fun(X) ->
        '__bp_int'((X + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:13:58">>)
    end},
    Dbl = {bp_load_cases_fn_expr_typed_in_record_field@main@@Op, <<"dbl">>, fun(X) ->
        '__bp_int'((X * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:15:18">>)
    end},
    '__bp_print'([erlang:element(2, Inc)]),
    '__bp_print'([apply(Inc, 5)]),
    '__bp_print'([apply(Dbl, 5)]),
    Fs = [fun(X) ->
        '__bp_int'((X - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/main.bp:20:37">>)
    end, fun(X) ->
        '__bp_int'((X * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:20:53">>)
    end],
    '__bp_print'([lists:map(fun(F) ->
        F(3)
    end, Fs)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/fn_expr_typed_in_record_field|*">>.

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

'__bp_priv__apply'(A0, A1) -> apply(A0, A1).
