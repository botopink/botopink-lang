-module(bp_load_cases_bytes_encoding_bridges@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__show'/1, '__bp_priv__errorName'/1]).

%% behavior bytes

%%% Decision 346 — `encoding`'s `Bytes` bridges: base64 and hex over bytes, lossless where the

%%% text codecs read the bytes back as UTF-8. A decoder answers `Result<Bytes, EncodingError>` with

%%% the text codecs' rules and `Error` variants (decision 486). The parent binary knew no `Bytes`.

%% import encoding, EncodingError

show(R) ->
    case R of
        {ok, B} ->
            <<"bytes ", ('__bp_text'(std@encoding:hexEncodeBytes(B)))/binary>>;
        {error, E} ->
            <<"error ", (errorName(E))/binary>>
    end.

errorName(E) ->
    case E of
        std@encoding@@EncodingError__v__notbase64 ->
            <<"NotBase64">>;
        std@encoding@@EncodingError__v__nothex ->
            <<"NotHex">>;
        std@encoding@@EncodingError__v__notpercentencoded ->
            <<"NotPercentEncoded">>
    end.

main() ->
    Hi = <<"hi">>,
    '__bp_print'([std@encoding:base64EncodeBytes(Hi)]),
    '__bp_print'([std@encoding:hexEncodeBytes(Hi)]),
    Raw = (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (Hi) end end)(std@encoding:hexDecodeBytes(<<"00ff80c3">>)),
    '__bp_print'([byte_size(Raw)]),
    '__bp_print'([std@encoding:base64EncodeBytes(Raw)]),
    '__bp_print'([show(std@encoding:base64DecodeBytes(<<"AP+Aww==">>))]),
    '__bp_print'([show(std@encoding:base64DecodeBytes(<<"AP+Aww">>))]),
    '__bp_print'([show(std@encoding:base64DecodeBytes(<<"aGk">>))]),
    '__bp_print'([show(std@encoding:base64DecodeBytes(<<"aGl">>))]),
    '__bp_print'([show(std@encoding:base64DecodeBytes(<<"a*b=">>))]),
    '__bp_print'([show(std@encoding:base64DecodeBytes(<<"">>))]),
    '__bp_print'([show(std@encoding:hexDecodeBytes(<<"00FFab">>))]),
    '__bp_print'([show(std@encoding:hexDecodeBytes(<<"abc">>))]),
    '__bp_print'([show(std@encoding:hexDecodeBytes(<<"zz">>))]),
    '__bp_print'([((fun(__BpR) -> case __BpR of {ok, __BpV1} -> __BpV1; _ -> (Hi) end end)(std@encoding:base64DecodeBytes(std@encoding:base64EncodeBytes(Raw))) =:= Raw)]),
    '__bp_print'([(std@encoding:base64Encode(<<"hi">>) =:= std@encoding:base64EncodeBytes(Hi))]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/bytes_encoding_bridges|*">>.

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

'__bp_priv__show'(A0) -> show(A0).

'__bp_priv__errorName'(A0) -> errorName(A0).
