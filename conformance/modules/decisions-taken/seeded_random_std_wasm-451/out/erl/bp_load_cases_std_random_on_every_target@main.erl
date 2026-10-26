-module(bp_load_cases_std_random_on_every_target@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__array_all'/2, '__bp_priv__string_slice'/3]).

%% behavior string

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

%%% `std/io/random` on all four targets (decision 238, `01-compiler/05-wasm`

%%% step 5): on wasm `float` is `std: "random.float"`, `seed` / `seededFloat`

%%% std-wasm's seeded stream, bound by `std:` cells (decision 451: the

%%% commonJS sidecar's Mulberry32 — the same draws after the same `seed`;

%%% erlang's `exsplus` draws others), and `shuffle`, `secureToken`, `uuidV4` and `randomBytes`

%%% private `fn:` bodies — a selection shuffle over one-element slices, bytes

%%% drawn from `random_get`. Each line prints what every target agrees on.

%% import random

main() ->
    R = std@io@random:float(),
    '__bp_print'([((R >= 0.0) andalso (R < 1.0))]),
    Unseeded = std@io@random:seededFloat(),
    '__bp_print'([((Unseeded >= 0.0) andalso (Unseeded < 1.0))]),
    std@io@random:seed(42),
    A = std@io@random:seededFloat(),
    A2 = std@io@random:seededFloat(),
    std@io@random:seed(42),
    '__bp_print'([(A =:= std@io@random:seededFloat())]),
    '__bp_print'([(A =/= A2)]),
    '__bp_print'([((A >= 0.0) andalso (A < 1.0))]),
    Ys = std@io@random:shuffle([1, 2, 3, 4, 5]),
    '__bp_print'([erlang:length(Ys)]),
    '__bp_print'([lists:foldl(fun(__X, __A) -> (fun(Acc, Y) ->
        '__bp_add'(Acc, Y)
    end)(__A, __X) end, 0, Ys)]),
    '__bp_print'([array_all([1, 2, 3, 4, 5], fun(X) ->
        lists:member(X, Ys)
    end)]),
    Empty = [],
    '__bp_print'([erlang:length(std@io@random:shuffle(Empty))]),
    Words = std@io@random:shuffle([<<"a">>, <<"b">>, <<"c">>]),
    '__bp_print'([((lists:member(<<"a">>, Words) andalso lists:member(<<"b">>, Words)) andalso lists:member(<<"c">>, Words))]),
    T = std@io@random:secureToken(32),
    '__bp_print'([erlang:length(unicode:characters_to_list(T))]),
    '__bp_print'([(((string:find(T, <<"+">>) =/= nomatch) orelse (string:find(T, <<"/">>) =/= nomatch)) orelse (string:find(T, <<"=">>) =/= nomatch))]),
    '__bp_print'([(std@io@random:secureToken(0) =:= <<"">>)]),
    '__bp_print'([(std@io@random:secureToken(16) =/= std@io@random:secureToken(16))]),
    U = std@io@random:uuidV4(),
    '__bp_print'([erlang:length(unicode:characters_to_list(U))]),
    '__bp_print'([lists:map(fun(G) ->
        erlang:length(unicode:characters_to_list(G))
    end, (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(U, <<"-">>))]),
    '__bp_print'([(string:prefix((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)((fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(U, <<"-">>), 2) of
        undefined ->
            <<"">>;
        __bp_nullish ->
            __bp_nullish
    end), <<"4">>) =/= nomatch)]),
    '__bp_print'([(string:find(<<"89ab">>, string_slice((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)((fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(U, <<"-">>), 3) of
        undefined ->
            <<"">>;
        __bp_nullish@1 ->
            __bp_nullish@1
    end), 0, 1)) =/= nomatch)]),
    '__bp_print'([array_all((fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(U, <<"">>), fun(C) ->
        (string:find(<<"0123456789abcdef-">>, C) =/= nomatch)
    end)]),
    H = std@io@random:randomBytes(16),
    '__bp_print'([erlang:length(unicode:characters_to_list(H))]),
    '__bp_print'([array_all((fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(H, <<"">>), fun(C) ->
        (string:find(<<"0123456789abcdef">>, C) =/= nomatch)
    end)]),
    '__bp_print'([(std@io@random:randomBytes(0) =:= <<"">>)]),
    N = std@io@random:intInRange(1, 6),
    '__bp_print'([((N >= 1) andalso (N =< 6))]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/std_random_on_every_target|*">>.

array_all(Self, Pred) ->
    (erlang:length(lists:filter(Pred, Self)) =:= erlang:length(Self)).

string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            (fun(__S, __A, __E) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, __F = case __E < 0 of true -> erlang:max(__N + __E, 0); false -> erlang:min(__E, __N) end, unicode:characters_to_binary(lists:sublist(__L, __B + 1, erlang:max(__F - __B, 0))) end)(Self, Start, End);
        false ->
            (fun(__S, __A) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, unicode:characters_to_binary(lists:nthtail(__B, __L)) end)(Self, Start)
    end.

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

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
    '__bp_load_siblings'(),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_load_siblings'() ->
    case code:which(?MODULE) of
        Path when erlang:is_list(Path) ->
            lists:foreach(fun(Src) ->
                case code:ensure_loaded(erlang:list_to_atom(filename:basename(Src, ".erl"))) of
                    {module, _} -> ok;
                    _ ->
                        case compile:file(Src, [binary, return_errors]) of
                            {ok, Mod, Bin} -> code:load_binary(Mod, Src, Bin);
                            Bad ->
                                io:format(standard_error, "error: ~ts does not compile - refusing to run~n  ~p~n", [Src, Bad]),
                                erlang:halt(1)
                        end
                end
            end, filelib:wildcard(filename:join(filename:dirname(Path), "*.erl")));
        _ -> ok
    end.

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__array_all'(A0, A1) -> array_all(A0, A1).

'__bp_priv__string_slice'(A0, A1, A2) -> string_slice(A0, A1, A2).
