-module(conformance_lib@sections).
-export([targets/0, headerOf/2, parseFile/1, renderFile/1, find/3, answeringTarget/3, same/5, renderCandidate/5, 'HEADER'/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__fail'/2, '__bp_priv__isTarget'/1, '__bp_priv__badBody'/1, '__bp_priv__sectionOf'/3, '__bp_priv__snapOfSection'/1, '__bp_priv__array_any'/2, '__bp_priv__string_slice'/3]).

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

%%% A module's `snapshot/main.snap` (decision 989 (5)): the sectioned file.

%%% 

%%%     botopink-cell 2                 the format and its version, always line 1

%%%     == <case>                       the case's answer on every target, the records of

%%%     out 1                             `records.bp`, one run per section

%%%     == <case> on <t>                the case's answer on target <t> alone (a departure;

%%%     out 2                             <t> one of commonJS, erlang, beam, wasm)

%%% 

%%% A case with no departure for the target it runs on answers its plain section on that target; a

%%% departure replaces the plain section whole (decision 475 (3), per case). A section's body is the

%%% text between its header and the next, kept as written: `parseFile` accepts only a file whose

%%% every body is the canonical spelling of its records, so `renderFile(parseFile(text))` is the

%%% file byte for byte. A `== ` line is never a record, so a body never swallows a header.

%% import Snap, Malformed, parseBody, renderBody, matches, candidate

%% Line 1 of the sectioned file.

'HEADER'() ->
    <<"botopink-cell 2">>.

%% The targets a departure names.

targets() ->
    [<<"commonJS">>, <<"erlang">>, <<"beam">>, <<"wasm">>].

%% One section: the case, the target it departs on (`null` for the plain one) and its records as written.

%% type Section: name, target, body

%% The sectioned file, in file order.

%% type SnapFile: sections

fail(Line, Reason) ->
    {error, {conformance_lib@records@@Malformed, Line, Reason}}.

isTarget(T) ->
    array_any(targets(), fun(X) ->
        (X =:= T)
    end).

%% The header line of a section.

headerOf(Name, Target) ->
    case Target of
        undefined ->
            <<"== ", Name/binary>>;
        T ->
            <<"== ", Name/binary, " on ", ('__bp_text'(T))/binary>>
    end.

%% Why a section's body is not its records' one spelling (`""` when it is).

badBody(S) ->
    case conformance_lib@records:parseBody(erlang:element(4, S)) of
        {ok, _} ->
            <<"">>;
        {error, M} ->
            <<"section `", (headerOf(erlang:element(2, S), erlang:element(3, S)))/binary, "` line ", ('__bp_text'(erlang:integer_to_binary(erlang:element(2, M))))/binary, ": ", ('__bp_text'(erlang:element(3, M)))/binary>>
    end.

%% Parse a sectioned file; a malformed one answers its 1-based line and the reason.

parseFile(Text) ->
    try
        case ((Text =:= <<"">>) orelse (not (fun(__S, __X) -> __N = byte_size(__S), __M = byte_size(__X), (__M =< __N) andalso (binary:part(__S, __N - __M, __M) =:= __X) end)(Text, <<"\n">>))) of
            true ->
                fail(erlang:length((fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(Text, <<"\n">>)), <<"every line ends with a newline">>);
            _ ->
                Lines = (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(string_slice(Text, 0, '__bp_int'((erlang:length(unicode:characters_to_list(Text)) - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/sections.bp:65:43">>)), <<"\n">>),
                case ((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Lines, 0) of
                    undefined ->
                        <<"">>;
                    __bp_nullish ->
                        __bp_nullish
                end) =/= 'HEADER'()) of
                    true ->
                        fail(1, <<"line 1 must be `", ('HEADER'())/binary, "`">>);
                    _ ->
                        Sections = [],
                        Name = <<"">>,
                        Target = undefined,
                        Body = <<"">>,
                        Open = false,
                        N = 1,
                        {N@3, Sections@5, Target@4, Name@4, Body@5, Open@4} = (fun __BpLoop({N@1, Sections@1, Target@1, Name@1, Body@1, Open@1}) ->
                            case (N@1 < erlang:length(Lines)) of
                                true ->
                                    Line = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Lines, N@1) of
                                        undefined ->
                                            <<"">>;
                                        __bp_nullish@1 ->
                                            __bp_nullish@1
                                    end,
                                    N@2 = '__bp_int'((N@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/sections.bp:76:15">>),
                                    {Sections@4, Target@3, Name@3, Body@4, Open@3} = case (string:prefix(Line, <<"== ">>) =/= nomatch) of
                                        true ->
                                            Sections@3 = case Open@1 of
                                                true ->
                                                    Sections@2 = (Sections@1 ++ [{conformance_lib@sections@@Section, Name@1, Target@1, Body@1}]),
                                                    Sections@2;
                                                _ ->
                                                    Sections@1
                                            end,
                                            Head = string_slice(Line, 3, undefined),
                                            On = (fun(__S, __X) -> case __X of <<>> -> 0; _ -> case binary:match(__S, __X) of nomatch -> -1; {__P, _} -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __P))) end end end)(Head, <<" on ">>),
                                            CaseName = case (On < 0) of
                                                true ->
                                                    Head;
                                                false ->
                                                    string_slice(Head, 0, On)
                                            end,
                                            Target@2 = case (On < 0) of
                                                true ->
                                                    undefined;
                                                false ->
                                                    string_slice(Head, '__bp_int'((On + 4), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/sections.bp:83:58">>), undefined)
                                            end,
                                            case ((CaseName =:= <<"">>) orelse (string:find(CaseName, <<" ">>) =/= nomatch)) of
                                                true ->
                                                    erlang:throw({'__bp_try', fail(N@2, <<"a section names one case: `== <case>` or `== <case> on <target>`">>)});
                                                _ -> ok
                                            end,
                                            case (not (((Target@2 =:= undefined) orelse isTarget(Target@2)))) of
                                                true ->
                                                    erlang:throw({'__bp_try', fail(N@2, <<"a departure names commonJS, erlang, beam or wasm">>)});
                                                _ -> ok
                                            end,
                                            case array_any(Sections@3, fun(S) ->
                                                ((erlang:element(2, S) =:= CaseName) andalso (erlang:element(3, S) =:= Target@2))
                                            end) of
                                                true ->
                                                    erlang:throw({'__bp_try', fail(N@2, <<"a section is written once">>)});
                                                _ -> ok
                                            end,
                                            Name@2 = CaseName,
                                            Body@2 = <<"">>,
                                            Open@2 = true,
                                            {Sections@3, Target@2, Name@2, Body@2, Open@2};
                                        _ ->
                                            case (not Open@1) of
                                                true ->
                                                    erlang:throw({'__bp_try', fail(N@2, <<"records come after a `== <case>` line">>)});
                                                _ -> ok
                                            end,
                                            Body@3 = <<Body@1/binary, ('__bp_text'(Line))/binary, "\n">>,
                                            {Sections@1, Target@1, Name@1, Body@3, Open@1}
                                    end,
                                    __BpLoop({N@2, Sections@4, Target@3, Name@3, Body@4, Open@3});
                                _ -> {N@1, Sections@1, Target@1, Name@1, Body@1, Open@1}
                            end
                        end)({N, Sections, Target, Name, Body, Open}),
                        Sections@7 = case Open@4 of
                            true ->
                                Sections@6 = (Sections@5 ++ [{conformance_lib@sections@@Section, Name@4, Target@4, Body@5}]),
                                Sections@6;
                            _ ->
                                Sections@5
                        end,
                        % Each body must be its records' one spelling.
                        K = 0,
                        K@3 = (fun __BpLoop(K@1) ->
                            case (K@1 < erlang:length(Sections@7)) of
                                true ->
                                    S = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Sections@7, K@1) of
                                        undefined ->
                                            {conformance_lib@sections@@Section, <<"">>, undefined, <<"">>};
                                        __bp_nullish@2 ->
                                            __bp_nullish@2
                                    end,
                                    K@2 = '__bp_int'((K@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/sections.bp:104:15">>),
                                    Bad = badBody(S),
                                    case (Bad =/= <<"">>) of
                                        true ->
                                            erlang:throw({'__bp_try', fail(1, Bad)});
                                        _ -> ok
                                    end,
                                    __BpLoop(K@2);
                                _ -> K@1
                            end
                        end)(K),
                        {ok, {conformance_lib@sections@@SnapFile, Sections@7}}
                end
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

%% The file's text: the header, then each section's header line and body.

renderFile(File) ->
    Out = <<('HEADER'())/binary, "\n">>,
    Out@3 = lists:foldl(fun(S, Out@1) ->
        Out@2 = <<Out@1/binary, (headerOf(erlang:element(2, S), erlang:element(3, S)))/binary, "\n", ('__bp_text'(erlang:element(4, S)))/binary>>,
        Out@2
    end, Out, erlang:element(2, File)),
    Out@3.

sectionOf(File, Name, Target) ->
    try
        lists:foreach(fun(S) ->
            case ((erlang:element(2, S) =:= Name) andalso (erlang:element(3, S) =:= Target)) of
                true ->
                    erlang:throw({'__bp_try', S});
                _ -> ok
            end
        end, erlang:element(2, File)),
        undefined
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

%% The section a case answers on `target`: its departure there when it has one, else its plain section.

find(File, Name, Target) ->
    Departure = sectionOf(File, Name, Target),
    case Departure of
        undefined ->
            sectionOf(File, Name, undefined);
        D ->
            D
    end.

%% The target of the section `find` would answer: `target` when the case departs there, else `null`.

answeringTarget(File, Name, Target) ->
    case (sectionOf(File, Name, Target) =/= undefined) of
        true ->
            Target;
        _ ->
            undefined
    end.

snapOfSection(S) ->
    case S of
        undefined ->
            undefined;
        X ->
            case conformance_lib@records:parseBody(erlang:element(4, X)) of
                {ok, TryV0} -> TryV0;
                {error, _TryE0} ->
                    undefined
            end
    end.

%% Whether the observed answer of `name` on `target` is the accepted one (`records.matches`):

%% a case the file does not have is not equal.

same(File, Name, Target, Observed, ObservedStderr) ->
    Accepted = snapOfSection(find(File, Name, Target)),
    case Accepted of
        undefined ->
            false;
        A ->
            conformance_lib@records:matches(A, Observed, ObservedStderr)
    end.

%% The candidate section for an observed answer: its header line and its records. The accepted

%% section's `stderr` claims that still hold are kept; a candidate never invents one.

renderCandidate(File, Name, Target, Observed, ObservedStderr) ->
    Cand = conformance_lib@records:candidate(snapOfSection(find(File, Name, Target)), Observed, ObservedStderr),
    <<(headerOf(Name, answeringTarget(File, Name, Target)))/binary, "\n", ('__bp_text'(conformance_lib@records:renderBody(Cand)))/binary>>.

array_any(Self, Pred) ->
    (erlang:length(lists:filter(Pred, Self)) =/= 0).

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

'__bp_priv__fail'(A0, A1) -> fail(A0, A1).

'__bp_priv__isTarget'(A0) -> isTarget(A0).

'__bp_priv__badBody'(A0) -> badBody(A0).

'__bp_priv__sectionOf'(A0, A1, A2) -> sectionOf(A0, A1, A2).

'__bp_priv__snapOfSection'(A0) -> snapOfSection(A0).

'__bp_priv__array_any'(A0, A1) -> array_any(A0, A1).

'__bp_priv__string_slice'(A0, A1, A2) -> string_slice(A0, A1, A2).
