-module(bp_load_cases_integer_never_negative_zero@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__zi'/0, '__bp_priv__zero'/0, '__bp_priv__same'/2]).

%%% Decision 214's premise: an integer is never `-0` — erlang, beam and wasm

%%% have no such value. JavaScript's `*`, `%`, unary `-` and a truncated `/`

%%% answer `-0` for `0 * -1`, `-x` with `x = 0`, `-4 % 2` and `0 / -3`, which

%%% commonJS printed as `-0` and which would make an `f64`'s total order (the

%%% run-time `__bp_eq` compares numbers with `Object.is`) tell two equal

%%% integers apart. The integer lowering canonicalises those four.

%%% 

%%% The last two rows go through a generic body, which on commonJS compares

%%% with `__bp_eq` whatever `T` is: two integer zeros are equal, an `f64`

%%% `0.0` and `-0.0` are not (`zero() * -1.0`, built at run time).

zi() ->
    0.

zero() ->
    0.0.

same(A, B) ->
    (A =:= B).

main() ->
    X = zi(),
    M = '__bp_int'((X * (-1)), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:28:15">>),
    N = '__bp_int'((-X), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/main.bp:29:13">>),
    R = ((-4) rem 2),
    Q = '__bp_int'((X div '__bp_nz'((-3), <<"integer division by zero: / on i32 at src/main.bp:31:15">>)), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/main.bp:31:15">>),
    '__bp_print'([M]),
    '__bp_print'([N]),
    '__bp_print'([R]),
    '__bp_print'([Q]),
    '__bp_print'([[M, N, R, Q]]),
    '__bp_print'([('__bp_int'((0 * (-1)), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:37:13">>) =:= 0)]),
    '__bp_print'([(M =:= 0)]),
    '__bp_print'([same(0, '__bp_int'((X * (-1)), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:39:21">>))]),
    '__bp_print'([same(0.0, (zero() * (-1.0)))]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/integer_never_negative_zero|*">>.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

-compile({inline,['__bp_nz'/2]}).
'__bp_nz'(B, What) when B == 0 -> erlang:error({panic, What});
'__bp_nz'(B, _) -> B.

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

'__bp_priv__zi'() -> zi().

'__bp_priv__zero'() -> zero().

'__bp_priv__same'(A0, A1) -> same(A0, A1).
