-module(bp_load_cases_comptime_text_one_answer@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__id'/1]).

%%% 1.0.12-beta `1-botopink-lang/144` B-00k (decisions 434 (5), 441, 443) —

%%% a text computed at comptime is std-wasm's, whatever the build's target:

%%% one comptime runtime, so the four targets print one answer. A float's

%%% text is OTP's (`5.0`, `1.0e21`, `1.0e-7`, as every target's own program prints it), `trim` keeps a

%%% NBSP (std-wasm's set: space, tab, LF, CR, VT, FF), and case mapping is

%%% OTP's over all of Unicode, the word-final sigma included (`ΟΔΟΣ` lowers

%%% to `οδοσ`, where a JS engine answers `οδος`).

%%% 

%%% The parent of the group (`239f789f`) ran commonJS's and wasm's comptime on

%%% the wat runtime, which refused the non-ASCII case mapping (`string case

%%% mapping of a non-ASCII character`), and erlang's and beam's on the BEAM.

id(X) ->
    X.

main() ->
    Five = <<"5.0">>,
    '__bp_print'([Five]),
    FiveText = <<"5.0">>,
    '__bp_print'([FiveText]),
    Big = <<"1.0e21">>,
    '__bp_print'([Big]),
    Small = <<"1.0e-7">>,
    '__bp_print'([Small]),
    Trimmed = <<"\x{C2}\x{A0}a">>,
    '__bp_print'([<<"[", Trimmed/binary, "]">>]),
    '__bp_print'([<<"\x{C3}\x{89}">>]),
    '__bp_print'([<<"STRASSE">>]),
    '__bp_print'([<<"\x{CE}\x{BF}\x{CE}\x{B4}\x{CE}\x{BF}\x{CF}\x{83}">>]),
    '__bp_print'([<<"\x{C3}\x{A9}cole">>]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/comptime_text_one_answer|*">>.

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

'__bp_priv__id'(A0) -> id(A0).
