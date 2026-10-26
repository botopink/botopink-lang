-module(bp_load_cases_fn_expr_typed_anywhere@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__twice'/2, '__bp_priv__adder'/1]).

%%% Decision 408 — the typed function expression `fn(x: T, …) -> R { … }` is

%%% legal in every position: a `val`, a `var`, an argument, a return. Where the

%%% position has a type the written types are checked against it; with none,

%%% the written types are the function's.

twice(F, V) ->
    F(F(V)).

adder(N) ->
    fun(X) ->
        '__bp_int'((X + N), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:14:18">>)
    end.

main() ->
    Inc = fun(X) ->
        '__bp_int'((X + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:20:18">>)
    end,
    '__bp_print'([Inc(1)]),
    Step = fun(X) ->
        '__bp_int'((X - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/main.bp:24:18">>)
    end,
    '__bp_print'([Step(10)]),
    Step@1 = fun(X) ->
        '__bp_int'((X - 2), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/main.bp:28:18">>)
    end,
    '__bp_print'([Step@1(10)]),
    Words = lists:map(fun(N) ->
        <<"n", ('__bp_text'(erlang:integer_to_binary(N)))/binary>>
    end, [1, 2, 3]),
    '__bp_print'([iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Words)))]),
    '__bp_print'([twice(fun(X) ->
        '__bp_int'((X * 3), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:36:18">>)
    end, 2)]),
    '__bp_print'([(adder(5))(1)]),
    G = fun(X) ->
        '__bp_int'((X + 100), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:40:18">>)
    end,
    '__bp_print'([G(1)]),
    Say = fun(S) ->
        '__bp_print'([S])
    end,
    Say(<<"hi">>).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/fn_expr_typed_anywhere|*">>.

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

'__bp_priv__twice'(A0, A1) -> twice(A0, A1).

'__bp_priv__adder'(A0) -> adder(A0).
