-module(bp_load_cases_fn_tail_value@main).
-compile({no_auto_import,[max/2]}).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__inc'/1, '__bp_priv__sign'/1, '__bp_priv__max'/2, '__bp_priv__first'/2, '__bp_priv__greet'/1, '__bp_priv__old'/1]).

%%% Decision 409 — a function body's last expression written without `;` is

%%% its value: `fn inc(x: i32) -> i32 { x + 1 }`. An early `return` stays

%%% (`sign`); an `if` / `else` expression is a tail like any other (`max`); a

%%% tail is checked against `-> R`, generic or not (`first`); every `return

%%% x;` stays valid (`old`).

inc(X) ->
    '__bp_int'((X + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:9:27">>).

sign(N) ->
    case (N < 0) of
        true ->
            (-1);
        _ ->
            N
    end.

max(A, B) ->
    case (A > B) of
        true ->
            A;
        false ->
            B
    end.

first(Xs, Fallback) ->
    case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Xs, 0) of
        undefined ->
            Fallback;
        __bp_nullish ->
            __bp_nullish
    end.

greet(Name) ->
    Greeting = <<"hello, ">>,
    <<Greeting/binary, Name/binary>>.

old(X) ->
    '__bp_int'((X * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:26:14">>).

main() ->
    '__bp_print'([inc(1)]),
    '__bp_print'([sign((-5))]),
    '__bp_print'([sign(5)]),
    '__bp_print'([max(3, 9)]),
    '__bp_print'([first([7, 8], 0)]),
    '__bp_print'([first([], <<"none">>)]),
    '__bp_print'([greet(<<"ana">>)]),
    '__bp_print'([old(4)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/fn_tail_value|*">>.

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

'__bp_priv__inc'(A0) -> inc(A0).

'__bp_priv__sign'(A0) -> sign(A0).

'__bp_priv__max'(A0, A1) -> max(A0, A1).

'__bp_priv__first'(A0, A1) -> first(A0, A1).

'__bp_priv__greet'(A0) -> greet(A0).

'__bp_priv__old'(A0) -> old(A0).
