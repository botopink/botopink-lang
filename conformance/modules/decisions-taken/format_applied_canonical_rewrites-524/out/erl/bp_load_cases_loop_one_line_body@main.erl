-module(bp_load_cases_loop_one_line_body@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__f'/1]).

%%% 1.0.10-beta `00 · 15-language-surface` step 4b — a one-statement lambda

%%% body needs no `;` before its `}`, in a collection loop and in a trailing

%%% lambda alike: both take the fn body's semicolon policy

%%% (`requiredExceptLast`). `for (xs) { x -> terminal.print(x) };` was a parse error

%%% (`this token cannot appear here`) while `{ x -> terminal.print(x); }` compiled.

%%% Specified by 15 as `loop (xs) { … }`; decision 105 renamed the collection

%%% loop to `for`, which is the spelling here. A `;` AFTER the loop's `}` is

%%% accepted and removed by `botopink format` (C-13, decision 524).

f(X) ->
    '__bp_int'((X + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:13:14">>).

main() ->
    Xs = [1, 2],
    Acc = 0,
    Acc@3 = lists:foldl(fun(X, Acc@1) ->
        Acc@2 = '__bp_int'((Acc@1 + f(X)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:20:19">>),
        Acc@2
    end, Acc, Xs),
    Ys = lists:map(fun(X@1) ->
        f(X@1)
    end, Xs),
    '__bp_print'(['__bp_add'(erlang:integer_to_binary(Acc@3), erlang:integer_to_binary(erlang:length(Ys)))]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/loop_one_line_body|*">>.

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

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

'__bp_priv__f'(A0) -> f(A0).
