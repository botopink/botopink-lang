-module(bp_load_cases_string_case_unicode@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% Decision 443 — `toUpper` / `toLower` map case over all of Unicode on the

%%% four targets: the simple mappings (`é` → `É`, `ǆ` → `Ǆ`, Greek, Cyrillic)

%%% and the unconditional full ones (`ß` → `SS`, `ﬁ` → `FI`, `İ` → `i̇`).

%%% commonJS maps with the JS engine, erlang and beam with

%%% `string:uppercase` / `lowercase`, wasm with std-wasm — OTP's answers.

%%% The one place they part, the final sigma (a JS engine lowers a word-final

%%% `Σ` to `ς`, OTP and wasm to `σ`), is not printed here: it is pinned on

%%% wasm by `codegen/tests/wat.zig`.

main() ->
    '__bp_print'([string:uppercase(<<"\x{C3}\x{A9}">>)]),
    '__bp_print'([string:uppercase(<<"stra\x{C3}\x{9F}e">>)]),
    '__bp_print'([string:lowercase(<<"\x{C3}\x{89}COLE">>)]),
    '__bp_print'([string:lowercase(<<"\x{CE}\x{A3}\x{CE}\x{91}">>)]),
    '__bp_print'([string:uppercase(<<"\x{CF}\x{83}\x{CE}\x{B1}\x{CF}\x{82}">>)]),
    '__bp_print'([string:uppercase(<<"\x{C7}\x{86}">>)]),
    '__bp_print'([string:uppercase(<<"\x{EF}\x{AC}\x{81}">>)]),
    '__bp_print'([erlang:length(unicode:characters_to_list(string:lowercase(<<"\x{C4}\x{B0}">>)))]),
    '__bp_print'([string:uppercase(<<"\x{D0}\x{BF}\x{D1}\x{80}\x{D0}\x{B8}\x{D0}\x{B2}\x{D0}\x{B5}\x{D1}\x{82}">>)]),
    '__bp_print'([string:uppercase(<<"\x{C5}\x{89}">>)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/string_case_unicode|*">>.

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
