-module(bp_load_cases_index_user_type@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2]).

%% behavior array

array_range(Start, Stop) ->
    case ((Stop - Start) =< 0) of
        true ->
            [];
        false ->
            case ((Stop - Start) =:= 1) of
                true ->
                    [Start];
                false ->
                    Count = (Stop - Start),
                    Low = array_range(Start, (Start + (Count div 2))),
                    High = array_range((Start + (Count div 2)), Stop),
                    '__bp_prim_append'(Low, High)
            end
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Half = array_repeat(Value, (Times div 2)),
            case ((Times rem 2) =:= 0) of
                true ->
                    '__bp_prim_append'(Half, Half);
                false ->
                    '__bp_prim_append'('__bp_prim_append'(Half, Half), [Value])
            end
    end.

%%% Decision 63 (amended 2026-09-19) — **this cell is the point of the rule.**

%%% The index expression has no typing rule of its own and no privileged list of

%%% receivers: it rewrites to a method call, so a library's own type becomes

%%% indexable by ANSWERING `at` / `slice`, with **no compiler change**. Nothing

%%% below names `Array`, `string` or `Dict`, and the compiler knows nothing

%%% about `Matrix` or `Registry`.

%%% 

%%% `Index<K, V>` and `Slice<V>` are ambient, like `Display` (decision 27) and

%%% for the same reason: the syntax has to find the method without the author

%%% having imported anything. There is no `from "std"` line in this file.

%%% 

%%%   `Matrix` answers both — `m[1]` is `m.at(1)` and `m[0..2]` is

%%%   `m.slice(0, 2)`. `slice` takes two arguments rather than one range because

%%%   there is no `Range` type in the language: `start..end` is an AST node, not

%%%   a value.

%%% 

%%%   `Registry` answers `Index<string, i32>`, so `K` is not tied to `i32` and

%%%   an absent key is decision 47's `null` — the same one exit point a `Dict`

%%%   comes out of, because it IS the same mechanism.

%%% 

%%% Measured 2026-09-21. commonJS is right throughout. erlang and beam differ in

%%% ONE way — an empty optional prints the atom `undefined` rather than `null`,

%%% decision 47's row (C-18). wasm prints the four lines too: a method's

%%% `return` boxes into its declared `?i32` (it returned the bare index, and the

%%% reader loaded through it — `16777216` for `1`), and a `?i32[]` prints as

%%% the array or `null` (it printed the row's heap address). Calling the two

%%% methods BY NAME answers the same, byte for byte: the index expression only

%%% reaches them.

%% type Matrix: rows

%% type Registry: names

main() ->
    M = {bp_load_cases_index_user_type@main@@Matrix, [[1, 2], [3, 4], [5, 6]]},
    '__bp_print'([bp_load_cases_index_user_type@main@@Matrix:at(M, 1)]),
    '__bp_print'([erlang:length(erlang:element(2, bp_load_cases_index_user_type@main@@Matrix:slice(M, 0, 2)))]),
    R = {bp_load_cases_index_user_type@main@@Registry, [<<"ana">>, <<"bo">>]},
    '__bp_print'([bp_load_cases_index_user_type@main@@Registry:at(R, <<"bo">>)]),
    '__bp_print'([bp_load_cases_index_user_type@main@@Registry:at(R, <<"zz">>)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/index_user_type|*">>.

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

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

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).
