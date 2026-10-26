-module(bp_load_cases_is_fn_narrows_unknown@main).
-compile({no_auto_import,[apply/2]}).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__makeClock'/0, '__bp_priv__twice'/1, '__bp_priv__build'/1, '__bp_priv__apply'/2]).

%%% Decision 254 — `x is fn(<params>) -> T` narrows an `unknown` to that

%%% function type, with a run-time check, and a call through the narrowed name

%%% type-checks against it. A factory stored as `unknown` (the shape rakun's

%%% bean registry holds) is narrowed and called; a value of another arity, or

%%% no function at all, fails the test.

%% type Clock: zone

makeClock() ->
    {bp_load_cases_is_fn_narrows_unknown@main@@Clock, <<"UTC">>}.

twice(N) ->
    '__bp_int'((N * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:16:14">>).

build(Factory) ->
    case erlang:is_function(Factory, 0) of
        true ->
            erlang:element(2, Factory());
        _ ->
            <<"not a factory">>
    end.

apply(F, N) ->
    case erlang:is_function(F, 1) of
        true ->
            F(N);
        _ ->
            (-1)
    end.

main() ->
    Stored = fun makeClock/0,
    '__bp_print'([build(Stored)]),
    '__bp_print'([build(fun() ->
        {bp_load_cases_is_fn_narrows_unknown@main@@Clock, <<"BRT">>}
    end)]),
    '__bp_print'([build(fun twice/1)]),
    '__bp_print'([build(<<"text">>)]),
    '__bp_print'([build(42)]),
    '__bp_print'([apply(fun twice/1, 21)]),
    '__bp_print'([apply(fun(X) ->
        '__bp_int'((X + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:37:26">>)
    end, 1)]),
    '__bp_print'([apply(fun makeClock/0, 1)]),
    Two = fun(A, B) ->
        A
    end,
    '__bp_print'([erlang:is_function(Two, 2)]),
    '__bp_print'([erlang:is_function(Two, 1)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/is_fn_narrows_unknown|*">>.

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

'__bp_priv__makeClock'() -> makeClock().

'__bp_priv__twice'(A0) -> twice(A0).

'__bp_priv__build'(A0) -> build(A0).

'__bp_priv__apply'(A0, A1) -> apply(A0, A1).
