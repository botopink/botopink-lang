-module(bp_load_cases_std_hash_on_every_target@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% `std/hash` on all four targets (decision 238, `01-compiler/05-wasm` step

%%% 5): on wasm every cell is bound with `fn:` to a private body in exact

%%% arithmetic, answering what Node's `crypto` answers — the digests, the MACs,

%%% PBKDF2, the constant-time compare and the content hashes in one program,

%%% since the wasm heap grows (decision 261). `contentHash` folds code points

%%% on every target (decision 260): a character above U+FFFF is one code point.

%% import hash

main() ->
    '__bp_print'([std@hash:sha256(<<"abc">>)]),
    '__bp_print'([std@hash:sha512(<<"abc">>)]),
    '__bp_print'([std@hash:md5(<<"h\x{C3}\x{A9}llo \x{E2}\x{82}\x{AC}">>)]),
    '__bp_print'([std@hash:sha1Base64(<<"dGhlIHNhbXBsZSBub25jZQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11">>)]),
    '__bp_print'([std@hash:sha256Base64Url(<<"hello world">>)]),
    '__bp_print'([std@hash:strongHash(<<"">>)]),
    '__bp_print'([std@hash:hmacSha256(<<"key">>, <<"The quick brown fox jumps over the lazy dog">>)]),
    '__bp_print'([std@hash:hmacSha256Base64Url(<<"secret">>, <<"header.payload">>)]),
    '__bp_print'([std@hash:pbkdf2Sha256(<<"p\x{C3}\x{A4}ssw\x{C3}\x{B6}rd">>, <<"salt">>, 2, 40)]),
    '__bp_print'([std@hash:pbkdf2Sha256(<<"password">>, <<"salt">>, 9, 32)]),
    '__bp_print'([std@hash:equalsConstantTime(<<"abcd">>, <<"abcd">>)]),
    '__bp_print'([std@hash:equalsConstantTime(<<"abcd">>, <<"abce">>)]),
    '__bp_print'([std@hash:equalsConstantTime(<<"abc">>, <<"abcd">>)]),
    '__bp_print'([std@hash:contentHash(<<"h\x{C3}\x{A9}llo \x{E2}\x{82}\x{AC}">>)]),
    '__bp_print'([std@hash:contentHash(<<"\x{F0}\x{9F}\x{8E}\x{89}">>)]),
    '__bp_print'([std@hash:contentHash(<<"a\x{F0}\x{9F}\x{8E}\x{89}b">>)]),
    '__bp_print'([std@hash:cacheKey([<<"user:1">>, <<"profile">>])]),
    '__bp_print'([std@hash:strongCacheKey([<<"user">>, <<"1:profile">>])]),
    '__bp_print'([std@hash:etag(<<"<p>hi</p>">>)]),
    '__bp_print'([std@hash:weakEtag(<<"<p>hi</p>">>)]),
    '__bp_print'([std@hash:matches(<<"<p>hi</p>">>, <<"*">>)]),
    '__bp_print'([std@hash:fingerprint(<<"app.js">>, <<"body{}">>)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/std_hash_on_every_target|*">>.

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
