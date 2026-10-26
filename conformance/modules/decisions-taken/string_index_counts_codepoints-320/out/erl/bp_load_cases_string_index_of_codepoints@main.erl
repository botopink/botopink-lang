-module(bp_load_cases_string_index_of_codepoints@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__string_slice'/3]).

%% behavior string

%%% Decisions 169, 240 and 320: a string index counts codepoints on every

%%% target, so the index `indexOf` answers is the one `at` reads back. `—`

%%% (U+2014) is three UTF-8 bytes and one codepoint: counted in bytes,

%%% `indexOf("X")` answered `5` on wasm and `at(3)` the last byte of the dash.

%%% A combining mark is a codepoint of its own (`"e\u{301}"` is two, where

%%% erlang's `string:length/1` counted one grapheme cluster), and a character

%%% outside the BMP is one (`"👍"` is two UTF-16 units on commonJS).

main() ->
    S = <<"a\x{E2}\x{80}\x{94}bXc">>,
    '__bp_print'([(fun(__S, __X) -> case __X of <<>> -> 0; _ -> case binary:match(__S, __X) of nomatch -> -1; {__P, _} -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __P))) end end end)(S, <<"X">>)]),
    '__bp_print'([(fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(S, 3)]),
    '__bp_print'([(fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(S, 1)]),
    E = <<"e\x{CC}\x{81}">>,
    '__bp_print'([erlang:length(unicode:characters_to_list(E))]),
    '__bp_print'([((fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(E, 1) =:= <<"\x{CC}\x{81}">>)]),
    '__bp_print'([((fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(E, (-1)) =:= <<"\x{CC}\x{81}">>)]),
    '__bp_print'([(fun(__S, __X) -> case __X of <<>> -> 0; _ -> case binary:match(__S, __X) of nomatch -> -1; {__P, _} -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __P))) end end end)(E, <<"\x{CC}\x{81}">>)]),
    '__bp_print'([string_slice(E, 0, 1)]),
    '__bp_print'([(string_slice(E, 1, undefined) =:= <<"\x{CC}\x{81}">>)]),
    M = <<"e\x{CC}\x{81}xe\x{CC}\x{81}">>,
    '__bp_print'([erlang:length(unicode:characters_to_list(M))]),
    '__bp_print'([(fun(__S, __X) -> case __X of <<>> -> 0; _ -> case binary:match(__S, __X) of nomatch -> -1; {__P, _} -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __P))) end end end)(M, <<"x">>)]),
    '__bp_print'([(fun(__S, __Sub) -> __L = byte_size(__S), __SL = byte_size(__Sub), __Find = fun __F(__I) -> case __I < 0 of true -> -1; false -> case binary:part(__S, __I, min(__SL, __L - __I)) =:= __Sub of true -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __I))); false -> __F(__I - 1) end end end, __Find(__L - __SL) end)(M, <<"e">>)]),
    '__bp_print'([(fun(__S, __Sub) -> __L = byte_size(__S), __SL = byte_size(__Sub), __Find = fun __F(__I) -> case __I < 0 of true -> -1; false -> case binary:part(__S, __I, min(__SL, __L - __I)) =:= __Sub of true -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __I))); false -> __F(__I - 1) end end end, __Find(__L - __SL) end)(M, <<"\x{CC}\x{81}">>)]),
    '__bp_print'([(string_slice(M, 1, 4) =:= <<"\x{CC}\x{81}xe">>)]),
    T = <<"\x{F0}\x{9F}\x{91}\x{8D}">>,
    '__bp_print'([erlang:length(unicode:characters_to_list(T))]),
    '__bp_print'([((fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(T, 0) =:= <<"\x{F0}\x{9F}\x{91}\x{8D}">>)]),
    '__bp_print'([((fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(T, 1) =:= undefined)]),
    A = <<"a\x{F0}\x{9F}\x{91}\x{8D}b\x{F0}\x{9F}\x{91}\x{8D}c">>,
    '__bp_print'([erlang:length(unicode:characters_to_list(A))]),
    '__bp_print'([(fun(__S, __X) -> case __X of <<>> -> 0; _ -> case binary:match(__S, __X) of nomatch -> -1; {__P, _} -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __P))) end end end)(A, <<"b">>)]),
    '__bp_print'([(fun(__S, __Sub) -> __L = byte_size(__S), __SL = byte_size(__Sub), __Find = fun __F(__I) -> case __I < 0 of true -> -1; false -> case binary:part(__S, __I, min(__SL, __L - __I)) =:= __Sub of true -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __I))); false -> __F(__I - 1) end end end, __Find(__L - __SL) end)(A, <<"\x{F0}\x{9F}\x{91}\x{8D}">>)]),
    '__bp_print'([(fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(A, 3)]),
    '__bp_print'([string_slice(A, 1, 3)]),
    '__bp_print'([string_slice(A, 4, undefined)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/string_index_of_codepoints|*">>.

string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            (fun(__S, __A, __E) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, __F = case __E < 0 of true -> erlang:max(__N + __E, 0); false -> erlang:min(__E, __N) end, unicode:characters_to_binary(lists:sublist(__L, __B + 1, erlang:max(__F - __B, 0))) end)(Self, Start, End);
        false ->
            (fun(__S, __A) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, unicode:characters_to_binary(lists:nthtail(__B, __L)) end)(Self, Start)
    end.

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

'__bp_priv__string_slice'(A0, A1, A2) -> string_slice(A0, A1, A2).
