-module(bp_load_cases_sibling_blocks_bind_one_name@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__pick'/1, '__bp_priv__loops'/0, '__bp_priv__arms'/1, '__bp_priv__after'/1]).

%%% Decision 205 — two sibling blocks may each bind the same name, since

%%% neither sees the other's: an `if` and its `else`, two `if`s in sequence,

%%% two loop bodies, two `case` arms' binders — and a block's binding followed by

%%% the function's own binding of the name once the block has closed (the inner

%%% one is no longer visible there). Each binding is its own block's; no target

%%% invents a scope for it, and none leaks one out of it. 01-compiler/04-js

%%% step 4: commonJS writes one `const` per block.

pick(Flag) ->
    case Flag of
        true ->
            N = 1,
            '__bp_print'([N]);
        false ->
            N@1 = 2,
            '__bp_print'([N@1])
    end,
    case Flag of
        true ->
            M = 10,
            '__bp_print'([M]);
        _ -> ok
    end,
    case (not Flag) of
        true ->
            M@1 = 20,
            '__bp_print'([M@1]);
        _ -> ok
    end,
    0.

loops() ->
    Total = 0,
    Total@3 = lists:foldl(fun(X, Total@1) ->
        Step = '__bp_int'((X * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:33:22">>),
        Total@2 = '__bp_int'((Total@1 + Step), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:34:23">>),
        Total@2
    end, Total, [1, 2]),
    Total@6 = lists:foldl(fun(X, Total@4) ->
        Step@1 = '__bp_int'((X * 100), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:37:22">>),
        Total@5 = '__bp_int'((Total@4 + Step@1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:38:23">>),
        Total@5
    end, Total@3, [3, 4]),
    Total@6.

%% type Shape
%%   Circle(radius)
%%   Square(side)

arms(S) ->
    case S of
        {bp_load_cases_sibling_blocks_bind_one_name@main@@Shape__v__circle, V} ->
            '__bp_int'(('__bp_int'((3 * V), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:50:24">>) * V), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:50:28">>);
        {bp_load_cases_sibling_blocks_bind_one_name@main@@Shape__v__square, V@1} ->
            '__bp_int'((V@1 * V@1), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:51:24">>)
    end.

'after'(Flag) ->
    case Flag of
        true ->
            N = 1,
            '__bp_print'([N]);
        _ -> ok
    end,
    N@1 = 2,
    N@1.

main() ->
    '__bp_print'([pick(true)]),
    '__bp_print'([pick(false)]),
    '__bp_print'([loops()]),
    '__bp_print'([arms({bp_load_cases_sibling_blocks_bind_one_name@main@@Shape__v__circle, 2})]),
    '__bp_print'([arms({bp_load_cases_sibling_blocks_bind_one_name@main@@Shape__v__square, 5})]),
    '__bp_print'(['after'(true)]),
    '__bp_print'(['after'(false)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/sibling_blocks_bind_one_name|*">>.

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

'__bp_priv__pick'(A0) -> pick(A0).

'__bp_priv__loops'() -> loops().

'__bp_priv__arms'(A0) -> arms(A0).

'__bp_priv__after'(A0) -> 'after'(A0).
