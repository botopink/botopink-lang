-module(bp_load_cases_std_unicode_on_every_target@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__cps'/1]).

%%% `std/unicode` on all four targets (`01-compiler/05-wasm` step 5, `02/97`

%%% step 16): `fromCodepoint` over `String.fromCodepoint` (decision 262),

%%% `codepoints` and `firstCodepoint` by code point — an astral character is

%%% one — and the four normalization forms over composed, decomposed and

%%% compatibility text, by std's own botopink normalizer over the generated

%%% Unicode tables on every target (decision 333 (A)) — one `.out`.

%% import unicode, NormalizationForm

cps(S) ->
    iolist_to_binary(lists:join(<<" ">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(C) ->
        erlang:integer_to_binary(C)
    end, std@unicode:codepoints(S))))).

main() ->
    '__bp_print'([std@unicode:fromCodepoint(65)]),
    '__bp_print'([std@unicode:fromCodepoint(233)]),
    '__bp_print'([std@unicode:fromCodepoint(127881)]),
    '__bp_print'([cps(<<"a\x{C3}\x{A9}\x{F0}\x{9F}\x{8E}\x{89}">>)]),
    '__bp_print'([erlang:length(std@unicode:codepoints(<<"">>))]),
    '__bp_print'([case std@unicode:firstCodepoint(<<"\x{F0}\x{9F}\x{8E}\x{89}x">>) of
        undefined ->
            (-1);
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([case std@unicode:firstCodepoint(<<"">>) of
        undefined ->
            (-1);
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([cps(std@unicode:normalize(<<"e\x{CC}\x{81}">>, std@unicode@@NormalizationForm__v__nfc))]),
    '__bp_print'([cps(std@unicode:normalize(<<"\x{C3}\x{A9}">>, std@unicode@@NormalizationForm__v__nfd))]),
    '__bp_print'([cps(std@unicode:normalize(<<"\x{EF}\x{AC}\x{81}\x{C2}\x{B2}">>, std@unicode@@NormalizationForm__v__nfkc))]),
    '__bp_print'([cps(std@unicode:normalize(<<"\x{C7}\x{85}">>, std@unicode@@NormalizationForm__v__nfkd))]),
    '__bp_print'([cps(std@unicode:normalize(<<"\x{ED}\x{95}\x{9C}">>, std@unicode@@NormalizationForm__v__nfd))]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/std_unicode_on_every_target|*">>.

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

'__bp_priv__cps'(A0) -> cps(A0).
