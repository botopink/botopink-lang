-module(bp_load_cases_numeric_suffix_positions@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__stat'/1, '__bp_priv__offset'/1, '__bp_priv__sum'/1, '__bp_priv__narrow'/1, '__bp_priv__scale_by'/2]).

%%% Decision 247 — a suffixed literal is the same literal wherever it stands:

%%% in a `case` guard, in a `case` arm body, in a parameter's default, in a

%%% default made of an expression and inside a lambda. The suffix is the

%%% checker's and never reaches a backend (`1577836800000l` in a guard was a

%%% `SyntaxError` in JS and an `erlc` syntax error on Erlang and BEAM). The

%%% same holds in a method's parameter default (`type`, associated, `implement`,

%%% a `behavior` default fn, a `type` variant's method), a record field default

%%% and a `case` guard inside a method body.

%% type Stamp: mtime

stat(N) ->
    case (N < 0) of
        true ->
            {error, <<"negative">>};
        _ ->
            {ok, {bp_load_cases_numeric_suffix_positions@main@@Stamp, N}}
    end.

offset(V) ->
    V.

sum(V) ->
    V.

narrow(V) ->
    V.

%% type Box: label, size

%% behavior Scale

scale_by(X, Factor) ->
    '__bp_int'((X * Factor), -9223372036854775808, 9223372036854775807, <<"integer overflow: * on i64 at src/main.bp:43:18">>).

%% behavior Tag

%% type Item: id

%% type Pick: n

%% type Level
%%   Low
%%   High

main() ->
    Stamp = stat(1577836900000),
    case Stamp of
        {ok, S} when (erlang:element(2, S) > 1577836800000) ->
            '__bp_print'([<<"after">>]);
        {ok, _} ->
            '__bp_print'([<<"before">>]);
        {error, E} ->
            '__bp_print'([E])
    end,
    case 3 of
        N when (N > 2) ->
            '__bp_print'([<<"big">>]);
        _ ->
            '__bp_print'([<<"small">>])
    end,
    case 2 of
        N@1 when ((N@1 =:= 2) andalso (N@1 < 9)) ->
            '__bp_print'([<<"two">>]);
        _ ->
            '__bp_print'([<<"other">>])
    end,
    Grown = case 1 of
        1 ->
            '__bp_int'((10 + 1), -9223372036854775808, 9223372036854775807, <<"integer overflow: + on i64 at src/main.bp:91:19">>);
        _ ->
            0
    end,
    '__bp_print'([Grown]),
    '__bp_print'([offset(7)]),
    '__bp_print'([sum((2 + 3))]),
    '__bp_print'([narrow(9)]),
    '__bp_print'([lists:map(fun(V) ->
        '__bp_int'((V + 5), -9223372036854775808, 9223372036854775807, <<"integer overflow: + on i64 at src/main.bp:98:33">>)
    end, [1, 2])]),
    Box = {bp_load_cases_numeric_suffix_positions@main@@Box, <<"b">>, 4},
    '__bp_print'([erlang:element(3, Box)]),
    '__bp_print'([bp_load_cases_numeric_suffix_positions@main@@Box:grow(Box, 6)]),
    '__bp_print'([bp_load_cases_numeric_suffix_positions@main@@Box:make(8)]),
    '__bp_print'([scale_by(2, 10)]),
    '__bp_print'([bp_load_cases_numeric_suffix_positions@main@@Item:tag({bp_load_cases_numeric_suffix_positions@main@@Item, 1}, 3)]),
    '__bp_print'([bp_load_cases_numeric_suffix_positions@main@@Pick:'band'({bp_load_cases_numeric_suffix_positions@main@@Pick, 9})]),
    '__bp_print'([bp_load_cases_numeric_suffix_positions@main@@Level:weight(bp_load_cases_numeric_suffix_positions@main@@Level__v__low, 5)]),
    '__bp_print'([<<"sum=", ('__bp_text'('__bp_int'((3 + 4), -9223372036854775808, 9223372036854775807, <<"integer overflow: + on i64 at src/main.bp:107:21">>)))/binary>>]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/numeric_suffix_positions|*">>.

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

'__bp_priv__stat'(A0) -> stat(A0).

'__bp_priv__offset'(A0) -> offset(A0).

'__bp_priv__sum'(A0) -> sum(A0).

'__bp_priv__narrow'(A0) -> narrow(A0).

'__bp_priv__scale_by'(A0, A1) -> scale_by(A0, A1).
