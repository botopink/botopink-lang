-module(bp_load_cases_union_narrowed_field_read@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__byTest'/1, '__bp_priv__byCase'/1]).

%%% Decision 810 (2) — a value narrowed out of a union is read as the member it

%%% was narrowed to: `k.tag` after `if (k is A)`, and in a `case` arm with a

%%% type pattern, answers the field on every target.

%% type A: tag, label

%% type B: size

byTest(K) ->
    case ((erlang:is_tuple(K) andalso (erlang:tuple_size(K) =:= 3)) andalso (erlang:element(1, K) =:= bp_load_cases_union_narrowed_field_read@main@@A)) of
        true ->
            '__bp_print'([erlang:element(2, K)]),
            '__bp_print'([erlang:element(3, K)]);
        false ->
            '__bp_print'([erlang:element(2, K)])
    end.

byCase(K) ->
    case K of
        A = A when ((erlang:is_tuple(A) andalso (erlang:tuple_size(A) =:= 3)) andalso (erlang:element(1, A) =:= bp_load_cases_union_narrowed_field_read@main@@A)) ->
            '__bp_print'(['__bp_int'((erlang:element(2, A) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:21:25">>)]);
        B = B when ((erlang:is_tuple(B) andalso (erlang:tuple_size(B) =:= 2)) andalso (erlang:element(1, B) =:= bp_load_cases_union_narrowed_field_read@main@@B)) ->
            '__bp_print'(['__bp_int'((erlang:element(2, B) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:24:26">>)])
    end.

main() ->
    byTest({bp_load_cases_union_narrowed_field_read@main@@A, 7, <<"seven">>}),
    byTest({bp_load_cases_union_narrowed_field_read@main@@B, 9}),
    byCase({bp_load_cases_union_narrowed_field_read@main@@A, 7, <<"seven">>}),
    byCase({bp_load_cases_union_narrowed_field_read@main@@B, 9}).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/union_narrowed_field_read|*">>.

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

'__bp_priv__byTest'(A0) -> byTest(A0).

'__bp_priv__byCase'(A0) -> byCase(A0).
