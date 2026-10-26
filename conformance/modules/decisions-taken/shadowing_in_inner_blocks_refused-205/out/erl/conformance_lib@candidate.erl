-module(conformance_lib@candidate).
-export([deliver/2, finish/3, 'CANDIDATE_PATH'/0, 'ACCEPTED_PATH'/0]).

%%% The `.new` of a run (decision 989 (6)): `snapshot/main.snap.new` holds the module's whole

%%% candidate file. The program never accepts a candidate — it never writes `snapshot/main.snap`

%%% (decision 67).

%% import writeText

%% import diff

%% import SnapFile, parseFile, renderFile, HEADER

%% import Observed, assemble, reds

%% Where the candidate goes, beside the accepted file.

'CANDIDATE_PATH'() ->
    <<"snapshot/main.snap.new">>.

%% The accepted file's path.

'ACCEPTED_PATH'() ->
    <<"snapshot/main.snap">>.

%% `text` written to the file at `path`, through `io.fs` on every target (decision 992: wasm's

%% `io.fs` is the other targets'). `Error` when the file cannot be written.

deliver(Path, Text) ->
    try
        Written = case std@io@fs:writeText(Path, Text) of
            {ok, TryV0} -> TryV0;
            {error, E} ->
                case true of
                    _ ->
                        erlang:throw({'__bp_try', {error, <<"cannot write ", Path/binary, ": ", ('__bp_text'(E))/binary>>}})
                end
        end,
        {ok, undefined}
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

%% The whole check of a module: its observed answers against the accepted file's text. `Ok` when

%% every case is green; else the candidate is delivered (a candidate when the text differs) and the

%% `Error` names the red cases and the candidate.

finish(Accepted, Observed, Target) ->
    try
        File = case conformance_lib@sections:parseFile(Accepted) of
            {ok, TryV0} -> TryV0;
            {error, M} ->
                case true of
                    _ ->
                        erlang:throw({'__bp_try', {error, <<"snapshot/main.snap line ", ('__bp_text'(erlang:integer_to_binary('__bp_field'(M, line))))/binary, ": ", ('__bp_text'('__bp_field'(M, reason)))/binary>>}})
                end
        end,
        Red = conformance_lib@observe:reds(File, Observed, Target),
        Text = conformance_lib@observe:assemble(File, Observed, Target),
        case ((erlang:length(Red) =:= 0) andalso (Text =:= conformance_lib@sections:renderFile(File))) of
            true ->
                {ok, undefined};
            _ ->
                % The verdict names the red cases whether or not the candidate could be written.
                Written = case deliver('CANDIDATE_PATH'(), Text) of
                    {ok, _} ->
                        <<"">>;
                    {error, M@1} ->
                        <<"\n", ('__bp_text'(M@1))/binary>>
                end,
                {error, <<('__bp_text'(erlang:integer_to_binary(erlang:length(Red))))/binary, " red on ", Target/binary, ": ", ('__bp_text'(iolist_to_binary(lists:join(<<", ">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Red)))))/binary, "\n", ('__bp_text'(conformance_lib@records:diff(conformance_lib@sections:renderFile(File), Text)))/binary, ('__bp_text'(Written))/binary>>}
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

'__bp_field'(V, F) when erlang:is_map(V) -> maps:get(F, V);
'__bp_field'(V, F) -> erlang:apply(erlang:element(1, V), '__bp_get', [V, F]).

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

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
