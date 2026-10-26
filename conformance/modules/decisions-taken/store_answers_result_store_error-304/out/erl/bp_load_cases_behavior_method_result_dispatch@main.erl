-module(bp_load_cases_behavior_method_result_dispatch@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__describe'/1, '__bp_priv__read'/2, '__bp_priv__readTwice'/2]).

%%% Decision 304 (144 B-13) — a behavior method declared `-> Result` dispatches

%%% and wraps as a function does: called through a parameter typed by the

%%% behavior, each implementation's `return v` is `Ok(v)`, its `throw e` is

%%% `Error(e)` and its `try` propagates the error; a `default fn` of the

%%% behavior that `try`s the dispatched method wraps the same.

%% behavior KeyValueStore

%% type Memory: prefix

%% type Layered: inner

describe(R) ->
    case R of
        {ok, V} ->
            <<"ok ", ('__bp_text'(V))/binary>>;
        {error, E} ->
            <<"error ", ('__bp_text'(E))/binary>>
    end.

read(Store, Key) ->
    describe('__bp_method'(get, Store, [Key])).

readTwice(Store, Key) ->
    describe('__bp_method'(getTwice, Store, [Key])).

main() ->
    Memory = {bp_load_cases_behavior_method_result_dispatch@main@@Memory, <<"m:">>},
    Layered = {bp_load_cases_behavior_method_result_dispatch@main@@Layered, Memory},
    '__bp_print'([read(Memory, <<"a">>)]),
    '__bp_print'([read(Memory, <<"">>)]),
    '__bp_print'([read(Layered, <<"b">>)]),
    '__bp_print'([read(Layered, <<"">>)]),
    '__bp_print'([read(Layered, <<"secret">>)]),
    '__bp_print'([readTwice(Memory, <<"c">>)]),
    '__bp_print'([readTwice(Layered, <<"">>)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/behavior_method_result_dispatch|*">>.

'__bp_method'(M, V, Args) when erlang:is_map(V) -> erlang:apply(maps:get(M, V), [V | Args]);
'__bp_method'(M, V, Args) ->
    T = case erlang:is_tuple(V) of true -> erlang:element(1, V); false -> V end,
    O = case string:split(erlang:atom_to_list(T), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> T end,
    erlang:apply(O, M, [V | Args]).

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

'__bp_priv__describe'(A0) -> describe(A0).

'__bp_priv__read'(A0, A1) -> read(A0, A1).

'__bp_priv__readTwice'(A0, A1) -> readTwice(A0, A1).
