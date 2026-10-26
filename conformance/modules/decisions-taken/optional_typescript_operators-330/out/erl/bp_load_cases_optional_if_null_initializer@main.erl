-module(bp_load_cases_optional_if_null_initializer@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__pick'/1, '__bp_priv__grade'/1, '__bp_priv__half'/1]).

%%% Decision 330 — an `if` with a `null` arm is an optional: absent when that

%%% arm is taken, the other arm's value when it is not — a present `0` or

%%% `false` included — as a `val` / `var` initializer, an assignment and a

%%% `return`, an `else if` chain and a float payload too, on every target.

pick(C) ->
    case C of
        true ->
            0;
        false ->
            undefined
    end.

grade(N) ->
    case (N > 10) of
        true ->
            2;
        false ->
            case (N > 5) of
                true ->
                    1;
                false ->
                    undefined
            end
    end.

half(C) ->
    case C of
        true ->
            0.5;
        false ->
            undefined
    end.

main() ->
    Words = [<<"alpha">>, <<"be">>],
    N = case (erlang:length(Words) > 5) of
        true ->
            3;
        false ->
            undefined
    end,
    Z = case (erlang:length(Words) > 1) of
        true ->
            0;
        false ->
            undefined
    end,
    '__bp_print'([case N of
        undefined ->
            (-1);
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([case Z of
        undefined ->
            (-1);
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([case pick(false) of
        undefined ->
            (-1);
        __bp_nullish@2 ->
            __bp_nullish@2
    end]),
    '__bp_print'([case pick(true) of
        undefined ->
            (-1);
        __bp_nullish@3 ->
            __bp_nullish@3
    end]),
    '__bp_print'([case grade(20) of
        undefined ->
            (-1);
        __bp_nullish@4 ->
            __bp_nullish@4
    end]),
    '__bp_print'([case grade(7) of
        undefined ->
            (-1);
        __bp_nullish@5 ->
            __bp_nullish@5
    end]),
    '__bp_print'([case grade(1) of
        undefined ->
            (-1);
        __bp_nullish@6 ->
            __bp_nullish@6
    end]),
    '__bp_print'([case half(true) of
        undefined ->
            (-1.0);
        __bp_nullish@7 ->
            __bp_nullish@7
    end]),
    '__bp_print'([case half(false) of
        undefined ->
            (-1.0);
        __bp_nullish@8 ->
            __bp_nullish@8
    end]),
    M = undefined,
    M@1 = case (pick(true) =/= undefined) of
        true ->
            0;
        false ->
            undefined
    end,
    '__bp_print'([case M@1 of
        undefined ->
            (-1);
        __bp_nullish@9 ->
            __bp_nullish@9
    end]),
    B = case (erlang:length(Words) > 5) of
        true ->
            false;
        false ->
            undefined
    end,
    '__bp_print'([case B of
        undefined ->
            true;
        __bp_nullish@10 ->
            __bp_nullish@10
    end]),
    '__bp_print'([N]),
    '__bp_print'([Z]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/optional_if_null_initializer|*">>.

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

'__bp_priv__grade'(A0) -> grade(A0).

'__bp_priv__half'(A0) -> half(A0).
