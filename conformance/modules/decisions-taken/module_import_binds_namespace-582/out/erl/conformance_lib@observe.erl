-module(conformance_lib@observe).
-export([refusalOf/7, refusedAnswer/3, ranAnswer/5, linesOf/1, reds/3, assemble/3, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__observedOf'/2, '__bp_priv__candidateBody'/3, '__bp_priv__kept'/4, '__bp_priv__appended'/2, '__bp_priv__string_slice'/3, '__bp_priv__array_any'/2]).

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

%%% What one case answered, as data, and the reading of a whole module's answers against its

%%% `snapshot/main.snap` (decision 989 (5), (9)).

%% import Snap, Refusal

%% import Section, SnapFile, same, find, answeringTarget, headerOf

%% import parseBody, renderBody, candidate

%% One case's observed answer: its records and, for an abort, the text its stderr held.

%% type Observed: name, snap, stderr

%% A refused load's diagnostic as the `refused` / `at` / `label` / `from` records of 475, 485, 532:

%% the whole `error…` line as `botopink build` prints it — `error[<code>]: ` when the diagnostic

%% carries a code its message does not already start with, `error: ` otherwise —, its location when it

%% points somewhere, the label beside the caret, the `called from` frames innermost first.

refusalOf(Code, Message, File, Line, Column, Label, Frames) ->
    Head = case ((Code =:= <<"">>) orelse (string:prefix(Message, <<Code/binary, ":">>) =/= nomatch)) of
        true ->
            <<"error: ", Message/binary>>;
        false ->
            <<"error[", Code/binary, "]: ", Message/binary>>
    end,
    At = case (File =:= <<"">>) of
        true ->
            undefined;
        false ->
            <<File/binary, ":", ('__bp_text'(erlang:integer_to_binary(Line)))/binary, ":", ('__bp_text'(erlang:integer_to_binary(Column)))/binary>>
    end,
    {conformance_lib@records@@Refusal, Head, At, Label, Frames}.

%% The answer of a case whose load refused: the build lines first (decision 904), then the refusals.

refusedAnswer(Name, BuildText, Refusals) ->
    {conformance_lib@observe@@Observed, Name, {conformance_lib@records@@Snap, Refusals, linesOf(BuildText), <<"">>, false, []}, <<"">>}.

%% The answer of a case that ran: the build lines, then what it printed, `abort` when the run failed.

ranAnswer(Name, BuildText, Printed, Failed, Failure) ->
    {conformance_lib@observe@@Observed, Name, {conformance_lib@records@@Snap, [], linesOf(BuildText), Printed, Failed, []}, Failure}.

%% A build text's lines, each without its newline (`""` has none).

linesOf(Text) ->
    case (Text =:= <<"">>) of
        true ->
            [];
        _ ->
            Body = case (fun(__S, __X) -> __N = byte_size(__S), __M = byte_size(__X), (__M =< __N) andalso (binary:part(__S, __N - __M, __M) =:= __X) end)(Text, <<"\n">>) of
                true ->
                    string_slice(Text, 0, '__bp_int'((erlang:length(unicode:characters_to_list(Text)) - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/observe.bp:41:35">>));
                false ->
                    Text
            end,
            (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(Body, <<"\n">>)
    end.

%% The cases whose observed answer on `target` is not the accepted one, in module order.

reds(File, Observed, Target) ->
    Out = [],
    Out@4 = lists:foldl(fun(O, Out@1) ->
        Out@3 = case (not conformance_lib@sections:same(File, erlang:element(2, O), Target, erlang:element(3, O), erlang:element(4, O))) of
            true ->
                Out@2 = (Out@1 ++ [erlang:element(2, O)]),
                Out@2;
            _ ->
                Out@1
        end,
        Out@3
    end, Out, Observed),
    Out@4.

observedOf(Observed, Name) ->
    try
        lists:foreach(fun(O) ->
            case (erlang:element(2, O) =:= Name) of
                true ->
                    erlang:throw({'__bp_try', O});
                _ -> ok
            end
        end, Observed),
        undefined
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

candidateBody(File, O, Target) ->
    Accepted = conformance_lib@sections:find(File, erlang:element(2, O), Target),
    Kept = undefined,
    Kept@2 = case Accepted of
        undefined -> Kept;
        A ->
            Kept@1 = case conformance_lib@records:parseBody(erlang:element(4, A)) of
                {ok, TryV0} -> TryV0;
                {error, _TryE0} ->
                    undefined
            end,
            Kept@1
    end,
    conformance_lib@records:renderBody(conformance_lib@records:candidate(Kept@2, erlang:element(3, O), erlang:element(4, O))).

kept(File, Observed, Target, S) ->
    O = observedOf(Observed, erlang:element(2, S)),
    case (O =:= undefined) of
        true ->
            <<"">>;
        _ ->
            Ob = O,
            Chosen = conformance_lib@sections:answeringTarget(File, erlang:element(2, S), Target),
            Head = <<('__bp_text'(conformance_lib@sections:headerOf(erlang:element(2, S), erlang:element(3, S))))/binary, "\n">>,
            case ((erlang:element(3, S) =:= Chosen) andalso (not conformance_lib@sections:same(File, erlang:element(2, S), Target, erlang:element(3, Ob), erlang:element(4, Ob)))) of
                true ->
                    <<Head/binary, (candidateBody(File, Ob, Target))/binary>>;
                _ ->
                    <<Head/binary, ('__bp_text'(erlang:element(4, S)))/binary>>
            end
    end.

appended(File, O) ->
    case array_any(erlang:element(2, File), fun(S) ->
        (erlang:element(2, S) =:= erlang:element(2, O))
    end) of
        true ->
            <<"">>;
        _ ->
            <<('__bp_text'(conformance_lib@sections:headerOf(erlang:element(2, O), undefined)))/binary, "\n", ('__bp_text'(conformance_lib@records:renderBody(conformance_lib@records:candidate(undefined, erlang:element(3, O), erlang:element(4, O)))))/binary>>
    end.

%% The module's whole candidate file for a run on `target`: the file's sections in its order, every

%% unchanged section byte for byte; a case whose answer differs gets the candidate in the section it

%% answered on `target` (its departure there, else its plain section); a case the file does not

%% have is appended as a plain section; a section of a case the module no longer has is dropped.

assemble(File, Observed, Target) ->
    Old = lists:map(fun(S) ->
        kept(File, Observed, Target, S)
    end, erlang:element(2, File)),
    Fresh = lists:map(fun(O) ->
        appended(File, O)
    end, Observed),
    <<"botopink-cell 2\n", ('__bp_text'(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Old)))))/binary, ('__bp_text'(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Fresh)))))/binary>>.

string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            (fun(__S, __A, __E) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, __F = case __E < 0 of true -> erlang:max(__N + __E, 0); false -> erlang:min(__E, __N) end, unicode:characters_to_binary(lists:sublist(__L, __B + 1, erlang:max(__F - __B, 0))) end)(Self, Start, End);
        false ->
            (fun(__S, __A) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, unicode:characters_to_binary(lists:nthtail(__B, __L)) end)(Self, Start)
    end.

array_any(Self, Pred) ->
    (erlang:length(lists:filter(Pred, Self)) =/= 0).

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__observedOf'(A0, A1) -> observedOf(A0, A1).

'__bp_priv__candidateBody'(A0, A1, A2) -> candidateBody(A0, A1, A2).

'__bp_priv__kept'(A0, A1, A2, A3) -> kept(A0, A1, A2, A3).

'__bp_priv__appended'(A0, A1) -> appended(A0, A1).

'__bp_priv__string_slice'(A0, A1, A2) -> string_slice(A0, A1, A2).

'__bp_priv__array_any'(A0, A1) -> array_any(A0, A1).
