-module(bp_load_cases_numeric_literal_suffixes@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__small'/1, '__bp_priv__wide'/1, '__bp_priv__kind'/1]).

%%% Decision 247 — Kotlin's suffixes, lower case, for every numeric type:

%%% `1.5f` is an `f32`, `1d` an `f64`, `42l` an `i64`, `42u` a `u32`, `42ul` a

%%% `u64`, `7u8` / `7i8` / `7u16` / `7i16` / `7isize` / `7usize` their types;

%%% an unsuffixed integer still takes the integer type its position asks for

%%% (`val k: i64 = 1`); a suffix types a number pattern, and the suffix is

%%% stripped before any backend sees the literal. Each line was refused by the

%%% parent binary (`1.5f` was the number `1.5` and the identifier `f`).

small(V) ->
    V.

wide(V) ->
    V.

kind(N) ->
    case N of
        0 ->
            <<"zero">>;
        1 ->
            <<"one">>;
        _ ->
            <<"many">>
    end.

main() ->
    X = 1.0,
    '__bp_print'([X]),
    '__bp_print'([small(1.5)]),
    '__bp_print'([wide(42)]),
    K = 1,
    '__bp_print'([K]),
    '__bp_print'([42]),
    '__bp_print'([42]),
    '__bp_print'([7]),
    '__bp_print'([7]),
    '__bp_print'([7]),
    '__bp_print'([7]),
    '__bp_print'([7]),
    '__bp_print'([7]),
    '__bp_print'([kind(0)]),
    '__bp_print'([kind(1)]),
    '__bp_print'([kind(9)]),
    '__bp_print'([255]),
    '__bp_print'([1_000]),
    '__bp_print'([2.5e1]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/numeric_literal_suffixes|*">>.

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

'__bp_priv__small'(A0) -> small(A0).

'__bp_priv__wide'(A0) -> wide(A0).

'__bp_priv__kind'(A0) -> kind(A0).
