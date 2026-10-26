-module(conformance_lib@records).
-export([parse/1, render/1, matches/3, candidate/3, diff/2, parseBody/1, renderBody/1, 'HEADER'/0, 'NEW_SUFFIX'/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__fail'/2, '__bp_priv__withAt'/2, '__bp_priv__withLabel'/2, '__bp_priv__withFrame'/2, '__bp_priv__record'/2, '__bp_priv__sameLines'/2, '__bp_priv__sameRefusal'/2, '__bp_priv__splitLines'/1, '__bp_priv__lcs'/3, '__bp_priv__string_slice'/3, '__bp_priv__array_slice'/3, '__bp_priv__array_all'/2]).

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

%%% The records of one case's answer (decisions 457, 475, 485, 789, 868, 989 (5)) — the port of

%%% `conformance/check/src/records.bp`, itself the port of `cell_snap.zig`, plus decision 789's

%%% `build` record. A module's `snapshot/main.snap` (`sections.bp`) holds one run of these records

%%% per case; `parseBody` and `renderBody` read and write that run without the file's header.

%%% 

%%% A run of records is one case's answer on one or every target, a record per line:

%%% 

%%%     botopink-cell 1                 the format and its version, always line 1

%%%     refused <message line>          the compiler refuses the module: its

%%%     at <file>:<line>:<col>            `error…` line, and where (when located)

%%%     label <text>                    the label printed beside the caret (485)

%%%     from <file>:<line>:<col>        one `called from` line of a raise at build,

%%%                                       innermost first (868)

%%%     build <text>                    one line a build body printed (789; `build`

%%%                                       alone for an empty line)

%%%     out <text>                      one line the program printed (`out` alone

%%%                                       for an empty line)

%%%     no-final-newline                the last `out` line ended without `\n`

%%%     abort                           the program exits non-zero

%%%     stderr <text>                   with `abort`: the program's stderr contains

%%%                                       this text

%%% 

%%% The records come in the console's order (decision 904) — `build` lines, then the

%%% refusals (`refused`, `at`, `label`, `from`) or the output, then `abort`, then the

%%% `stderr` claims; nothing prints after a refusal, so a `build` after a `refused` is

%%% malformed — and a

%%% file has exactly one spelling: it parses only when rendering what it parsed

%%% gives back its text. A refusal and an output never share a file. The header

%%% alone is the empty answer.

%%% 

%%% Everything but `stderr` is compared exactly; a `stderr` line is a claim the

%%% abort's stderr contains.

%%% 

%%% Text, not bytes: the program runs on commonJS, where a string is UTF-16. Every

%%% cut here is at an ASCII `\n` or ` `, which no UTF-8 multi-byte sequence holds,

%%% so each piece is the same text `cell_snap.zig` cuts from the file's bytes.

%% The header the records grammar below is written against (a section carries none: the file's

%% line 1 is `sections.HEADER`).

'HEADER'() ->
    <<"botopink-cell 1">>.

%% A candidate's suffix, beside the accepted file it would replace.

'NEW_SUFFIX'() ->
    <<".new">>.

%% One refusal of a module: the compiler's `error…` line, its location when the

%% diagnostic carries one, the label beside the caret, and the `called from`

%% frames (`from` records; `from` is a reserved word, so the field is `frames`).

%% type Refusal: message, at, label, frames

%% One module's answer.

%% type Snap: refusals, build, stdout, abort, stderr

%% Why a `.snap` did not parse: its 1-based line and the reason.

%% type Malformed: line, reason

fail(Line, Reason) ->
    {error, {conformance_lib@records@@Malformed, Line, Reason}}.

withAt(R, At) ->
    {conformance_lib@records@@Refusal, erlang:element(2, R), At, erlang:element(4, R), erlang:element(5, R)}.

withLabel(R, Label) ->
    {conformance_lib@records@@Refusal, erlang:element(2, R), erlang:element(3, R), Label, erlang:element(5, R)}.

withFrame(R, Frame) ->
    {conformance_lib@records@@Refusal, erlang:element(2, R), erlang:element(3, R), erlang:element(4, R), (erlang:element(5, R) ++ [Frame])}.

%% Parse a `.snap`; a malformed one answers its line and the reason.

parse(Text) ->
    try
        case ((Text =:= <<"">>) orelse (not (fun(__S, __X) -> __N = byte_size(__S), __M = byte_size(__X), (__M =< __N) andalso (binary:part(__S, __N - __M, __M) =:= __X) end)(Text, <<"\n">>))) of
            true ->
                fail(erlang:length((fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(Text, <<"\n">>)), <<"every record ends with a newline">>);
            _ ->
                Lines = (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(string_slice(Text, 0, '__bp_int'((erlang:length(unicode:characters_to_list(Text)) - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/records.bp:98:43">>)), <<"\n">>),
                Refusals = [],
                Build = [],
                Stdout = <<"">>,
                Stderr = [],
                Abort = false,
                % 0 start · 1 build · 2 output · 3 after `no-final-newline` · 4 after `abort` · 5 stderr · 6 refusals
                Phase = 0,
                LastOutEmpty = false,
                N = 0,
                {N@3, Phase@17, Refusals@10, Build@8, Stdout@11, LastOutEmpty@9, Abort@11, Stderr@12} = (fun __BpLoop({N@1, Phase@1, Refusals@1, Build@1, Stdout@1, LastOutEmpty@1, Abort@1, Stderr@1}) ->
                    case (N@1 < erlang:length(Lines)) of
                        true ->
                            __BpLoop(try
                                Line = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Lines, N@1) of
                                    undefined ->
                                        <<"">>;
                                    __bp_nullish ->
                                        __bp_nullish
                                end,
                                N@2 = '__bp_int'((N@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/records.bp:110:15">>),
                                case (N@2 =:= 1) of
                                    true ->
                                        case (Line =/= 'HEADER'()) of
                                            true ->
                                                erlang:throw({'__bp_try', fail(N@2, <<"line 1 must be `botopink-cell 1`">>)});
                                            _ -> ok
                                        end,
                                        erlang:throw({'__bp_cond_continue', {N@2, Phase@1, Refusals@1, Build@1, Stdout@1, LastOutEmpty@1, Abort@1, Stderr@1}});
                                    _ -> ok
                                end,
                                Space = (fun(__S, __X) -> case __X of <<>> -> 0; _ -> case binary:match(__S, __X) of nomatch -> -1; {__P, _} -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __P))) end end end)(Line, <<" ">>),
                                Word = case (Space < 0) of
                                    true ->
                                        Line;
                                    false ->
                                        string_slice(Line, 0, Space)
                                end,
                                HasRest = (Space >= 0),
                                Rest = case (Space < 0) of
                                    true ->
                                        <<"">>;
                                    false ->
                                        string_slice(Line, '__bp_int'((Space + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/records.bp:119:60">>), undefined)
                                end,
                                case (HasRest andalso (Rest =:= <<"">>)) of
                                    true ->
                                        erlang:throw({'__bp_try', fail(N@2, <<"a record's text is never empty (an empty output line is `out` alone)">>)});
                                    _ -> ok
                                end,
                                Count = erlang:length(Refusals@1),
                                Last = (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Refusals@1, '__bp_int'((Count - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/records.bp:123:48">>)),
                                {Phase@16, Refusals@9, Build@7, Stdout@10, LastOutEmpty@8, Abort@10, Stderr@11} = case (Word =:= <<"refused">>) of
                                    true ->
                                        case ((Phase@1 > 1) andalso (Phase@1 =/= 6)) of
                                            true ->
                                                erlang:throw({'__bp_try', fail(N@2, <<"`refused` comes before any output">>)});
                                            _ -> ok
                                        end,
                                        Phase@2 = 6,
                                        case (not HasRest) of
                                            true ->
                                                erlang:throw({'__bp_try', fail(N@2, <<"`refused` names the compiler's message">>)});
                                            _ -> ok
                                        end,
                                        Refusals@2 = (Refusals@1 ++ [{conformance_lib@records@@Refusal, Rest, undefined, undefined, []}]),
                                        {Phase@2, Refusals@2, Build@1, Stdout@1, LastOutEmpty@1, Abort@1, Stderr@1};
                                    _ ->
                                        {Refusals@8, Phase@15, Build@6, Stdout@9, LastOutEmpty@7, Abort@9, Stderr@10} = case (Word =:= <<"at">>) of
                                            true ->
                                                case (not HasRest) of
                                                    true ->
                                                        erlang:throw({'__bp_try', fail(N@2, <<"`at` names `<file>:<line>:<col>`">>)});
                                                    _ -> ok
                                                end,
                                                case (((Phase@1 =/= 6) orelse (Count =:= 0)) orelse ((fun(undefined) -> undefined; (_Opt0) -> erlang:element(3, _Opt0) end)(Last) =/= undefined)) of
                                                    true ->
                                                        erlang:throw({'__bp_try', fail(N@2, <<"`at` follows its `refused` line">>)});
                                                    _ -> ok
                                                end,
                                                Refusals@3 = (array_slice(Refusals@1, 0, '__bp_int'((Count - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/records.bp:137:33">>)) ++ [withAt(case Last of
                                                    undefined ->
                                                        {conformance_lib@records@@Refusal, <<"">>, undefined, undefined, []};
                                                    __bp_nullish@1 ->
                                                        __bp_nullish@1
                                                end, Rest)]),
                                                {Refusals@3, Phase@1, Build@1, Stdout@1, LastOutEmpty@1, Abort@1, Stderr@1};
                                            _ ->
                                                {Refusals@7, Phase@14, Build@5, Stdout@8, LastOutEmpty@6, Abort@8, Stderr@9} = case (Word =:= <<"label">>) of
                                                    true ->
                                                        case (not HasRest) of
                                                            true ->
                                                                erlang:throw({'__bp_try', fail(N@2, <<"`label` names the text printed beside the caret">>)});
                                                            _ -> ok
                                                        end,
                                                        case ((((Phase@1 =/= 6) orelse (Count =:= 0)) orelse ((fun(undefined) -> undefined; (_Opt2) -> erlang:element(3, _Opt2) end)(Last) =:= undefined)) orelse ((fun(undefined) -> undefined; (_Opt1) -> erlang:element(4, _Opt1) end)(Last) =/= undefined)) of
                                                            true ->
                                                                erlang:throw({'__bp_try', fail(N@2, <<"`label` follows its `at` line">>)});
                                                            _ -> ok
                                                        end,
                                                        Refusals@4 = (array_slice(Refusals@1, 0, '__bp_int'((Count - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/records.bp:148:33">>)) ++ [withLabel(case Last of
                                                            undefined ->
                                                                {conformance_lib@records@@Refusal, <<"">>, undefined, undefined, []};
                                                            __bp_nullish@2 ->
                                                                __bp_nullish@2
                                                        end, Rest)]),
                                                        {Refusals@4, Phase@1, Build@1, Stdout@1, LastOutEmpty@1, Abort@1, Stderr@1};
                                                    _ ->
                                                        {Refusals@6, Phase@13, Build@4, Stdout@7, LastOutEmpty@5, Abort@7, Stderr@8} = case (Word =:= <<"from">>) of
                                                            true ->
                                                                case (not HasRest) of
                                                                    true ->
                                                                        erlang:throw({'__bp_try', fail(N@2, <<"`from` names `<file>:<line>:<col>`">>)});
                                                                    _ -> ok
                                                                end,
                                                                case (((Phase@1 =/= 6) orelse (Count =:= 0)) orelse ((fun(undefined) -> undefined; (_Opt3) -> erlang:element(3, _Opt3) end)(Last) =:= undefined)) of
                                                                    true ->
                                                                        erlang:throw({'__bp_try', fail(N@2, <<"`from` follows its `at` line">>)});
                                                                    _ -> ok
                                                                end,
                                                                Refusals@5 = (array_slice(Refusals@1, 0, '__bp_int'((Count - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/records.bp:155:33">>)) ++ [withFrame(case Last of
                                                                    undefined ->
                                                                        {conformance_lib@records@@Refusal, <<"">>, undefined, undefined, []};
                                                                    __bp_nullish@3 ->
                                                                        __bp_nullish@3
                                                                end, Rest)]),
                                                                {Refusals@5, Phase@1, Build@1, Stdout@1, LastOutEmpty@1, Abort@1, Stderr@1};
                                                            _ ->
                                                                {Phase@12, Build@3, Stdout@6, LastOutEmpty@4, Abort@6, Stderr@7} = case (Word =:= <<"build">>) of
                                                                    true ->
                                                                        case (Phase@1 =:= 6) of
                                                                            true ->
                                                                                erlang:throw({'__bp_try', fail(N@2, <<"`build` comes before `refused`: nothing prints after a refusal">>)});
                                                                            _ -> ok
                                                                        end,
                                                                        case (Phase@1 > 1) of
                                                                            true ->
                                                                                erlang:throw({'__bp_try', fail(N@2, <<"`build` comes before `out`, `no-final-newline`, `abort` and `stderr`">>)});
                                                                            _ -> ok
                                                                        end,
                                                                        Phase@3 = 1,
                                                                        Build@2 = (Build@1 ++ [Rest]),
                                                                        {Phase@3, Build@2, Stdout@1, LastOutEmpty@1, Abort@1, Stderr@1};
                                                                    _ ->
                                                                        {Phase@11, Stdout@5, LastOutEmpty@3, Abort@5, Stderr@6} = case (Word =:= <<"out">>) of
                                                                            true ->
                                                                                case (Count > 0) of
                                                                                    true ->
                                                                                        erlang:throw({'__bp_try', fail(N@2, <<"a refused module prints nothing">>)});
                                                                                    _ -> ok
                                                                                end,
                                                                                case (Phase@1 > 2) of
                                                                                    true ->
                                                                                        erlang:throw({'__bp_try', fail(N@2, <<"`out` comes before `no-final-newline`, `abort` and `stderr`">>)});
                                                                                    _ -> ok
                                                                                end,
                                                                                Phase@4 = 2,
                                                                                Stdout@2 = <<Stdout@1/binary, ('__bp_text'(Rest))/binary, "\n">>,
                                                                                LastOutEmpty@2 = (not HasRest),
                                                                                {Phase@4, Stdout@2, LastOutEmpty@2, Abort@1, Stderr@1};
                                                                            _ ->
                                                                                {Stdout@4, Phase@10, Abort@4, Stderr@5} = case (Word =:= <<"no-final-newline">>) of
                                                                                    true ->
                                                                                        case HasRest of
                                                                                            true ->
                                                                                                erlang:throw({'__bp_try', fail(N@2, <<"`no-final-newline` takes no text">>)});
                                                                                            _ -> ok
                                                                                        end,
                                                                                        case (Phase@1 =/= 2) of
                                                                                            true ->
                                                                                                erlang:throw({'__bp_try', fail(N@2, <<"`no-final-newline` follows the last `out` line">>)});
                                                                                            _ -> ok
                                                                                        end,
                                                                                        case LastOutEmpty@1 of
                                                                                            true ->
                                                                                                erlang:throw({'__bp_try', fail(N@2, <<"`no-final-newline` after an empty `out` line has one spelling: drop both">>)});
                                                                                            _ -> ok
                                                                                        end,
                                                                                        Stdout@3 = string_slice(Stdout@1, 0, '__bp_int'((erlang:length(unicode:characters_to_list(Stdout@1)) - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/records.bp:177:52">>)),
                                                                                        Phase@5 = 3,
                                                                                        {Stdout@3, Phase@5, Abort@1, Stderr@1};
                                                                                    _ ->
                                                                                        {Abort@3, Phase@9, Stderr@4} = case (Word =:= <<"abort">>) of
                                                                                            true ->
                                                                                                case HasRest of
                                                                                                    true ->
                                                                                                        erlang:throw({'__bp_try', fail(N@2, <<"`abort` takes no text \x{E2}\x{80}\x{94} the exit status is never pinned">>)});
                                                                                                    _ -> ok
                                                                                                end,
                                                                                                case (Count > 0) of
                                                                                                    true ->
                                                                                                        erlang:throw({'__bp_try', fail(N@2, <<"a refused module does not run">>)});
                                                                                                    _ -> ok
                                                                                                end,
                                                                                                case (Phase@1 > 3) of
                                                                                                    true ->
                                                                                                        erlang:throw({'__bp_try', fail(N@2, <<"`abort` is written once, after the output">>)});
                                                                                                    _ -> ok
                                                                                                end,
                                                                                                Abort@2 = true,
                                                                                                Phase@6 = 4,
                                                                                                {Abort@2, Phase@6, Stderr@1};
                                                                                            _ ->
                                                                                                {Phase@8, Stderr@3} = case (Word =:= <<"stderr">>) of
                                                                                                    true ->
                                                                                                        case (not HasRest) of
                                                                                                            true ->
                                                                                                                erlang:throw({'__bp_try', fail(N@2, <<"`stderr` names the text the abort's stderr contains">>)});
                                                                                                            _ -> ok
                                                                                                        end,
                                                                                                        case (not Abort@1) of
                                                                                                            true ->
                                                                                                                erlang:throw({'__bp_try', fail(N@2, <<"`stderr` names an abort: it follows `abort`">>)});
                                                                                                            _ -> ok
                                                                                                        end,
                                                                                                        Phase@7 = 5,
                                                                                                        Stderr@2 = (Stderr@1 ++ [Rest]),
                                                                                                        {Phase@7, Stderr@2};
                                                                                                    _ ->
                                                                                                        erlang:throw({'__bp_try', fail(N@2, <<"unknown record (refused, at, label, from, build, out, no-final-newline, abort, stderr)">>)}),
                                                                                                        {Phase@1, Stderr@1}
                                                                                                end,
                                                                                                {Abort@1, Phase@8, Stderr@3}
                                                                                        end,
                                                                                        {Stdout@1, Phase@9, Abort@3, Stderr@4}
                                                                                end,
                                                                                {Phase@10, Stdout@4, LastOutEmpty@1, Abort@4, Stderr@5}
                                                                        end,
                                                                        {Phase@11, Build@1, Stdout@5, LastOutEmpty@3, Abort@5, Stderr@6}
                                                                end,
                                                                {Refusals@1, Phase@12, Build@3, Stdout@6, LastOutEmpty@4, Abort@6, Stderr@7}
                                                        end,
                                                        {Refusals@6, Phase@13, Build@4, Stdout@7, LastOutEmpty@5, Abort@7, Stderr@8}
                                                end,
                                                {Refusals@7, Phase@14, Build@5, Stdout@8, LastOutEmpty@6, Abort@8, Stderr@9}
                                        end,
                                        {Phase@15, Refusals@8, Build@6, Stdout@9, LastOutEmpty@7, Abort@9, Stderr@10}
                                end,
                                {N@2, Phase@16, Refusals@9, Build@7, Stdout@10, LastOutEmpty@8, Abort@10, Stderr@11}
                            catch
                                throw:{'__bp_cond_continue', __BpGroup1} -> __BpGroup1
                            end);
                        _ -> {N@1, Phase@1, Refusals@1, Build@1, Stdout@1, LastOutEmpty@1, Abort@1, Stderr@1}
                    end
                end)({N, Phase, Refusals, Build, Stdout, LastOutEmpty, Abort, Stderr}),
                Snap = {conformance_lib@records@@Snap, Refusals@10, Build@8, Stdout@11, Abort@11, Stderr@12},
                % One spelling: whatever the rules above let through must render back.
                case (render(Snap) =/= Text) of
                    true ->
                        fail(N@3, <<"not the canonical spelling of its records">>);
                    _ ->
                        {ok, Snap}
                end
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

record(Word, Text) ->
    case (Text =:= <<"">>) of
        true ->
            <<Word/binary, "\n">>;
        false ->
            <<Word/binary, " ", Text/binary, "\n">>
    end.

%% The one spelling of `snap`.

render(Snap) ->
    Out = <<('HEADER'())/binary, "\n">>,
    Out@3 = lists:foldl(fun(B, Out@1) ->
        Out@2 = <<Out@1/binary, (record(<<"build">>, B))/binary>>,
        Out@2
    end, Out, erlang:element(3, Snap)),
    Out@13 = lists:foldl(fun(R, Out@4) ->
        Out@5 = <<Out@4/binary, "refused ", ('__bp_text'(erlang:element(2, R)))/binary, "\n">>,
        Out@7 = case erlang:element(3, R) of
            undefined -> Out@5;
            At ->
                Out@6 = <<Out@5/binary, "at ", ('__bp_text'(At))/binary, "\n">>,
                Out@6
        end,
        Out@9 = case erlang:element(4, R) of
            undefined -> Out@7;
            L ->
                Out@8 = <<Out@7/binary, "label ", ('__bp_text'(L))/binary, "\n">>,
                Out@8
        end,
        Out@12 = lists:foldl(fun(F, Out@10) ->
            Out@11 = <<Out@10/binary, "from ", ('__bp_text'(F))/binary, "\n">>,
            Out@11
        end, Out@9, erlang:element(5, R)),
        Out@12
    end, Out@3, erlang:element(2, Snap)),
    Out@19 = case (erlang:element(4, Snap) =/= <<"">>) of
        true ->
            Ends = (fun(__S, __X) -> __N = byte_size(__S), __M = byte_size(__X), (__M =< __N) andalso (binary:part(__S, __N - __M, __M) =:= __X) end)(erlang:element(4, Snap), <<"\n">>),
            Body = case Ends of
                true ->
                    string_slice(erlang:element(4, Snap), 0, '__bp_int'((erlang:length(unicode:characters_to_list(erlang:element(4, Snap))) - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/records.bp:230:53">>));
                false ->
                    erlang:element(4, Snap)
            end,
            Out@16 = lists:foldl(fun(Line, Out@14) ->
                Out@15 = <<Out@14/binary, (record(<<"out">>, Line))/binary>>,
                Out@15
            end, Out@13, (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(Body, <<"\n">>)),
            Out@18 = case (not Ends) of
                true ->
                    Out@17 = <<Out@16/binary, "no-final-newline\n">>,
                    Out@17;
                _ ->
                    Out@16
            end,
            Out@18;
        _ ->
            Out@13
    end,
    Out@21 = case erlang:element(5, Snap) of
        true ->
            Out@20 = <<Out@19/binary, "abort\n">>,
            Out@20;
        _ ->
            Out@19
    end,
    Out@24 = lists:foldl(fun(S, Out@22) ->
        Out@23 = <<Out@22/binary, "stderr ", ('__bp_text'(S))/binary, "\n">>,
        Out@23
    end, Out@21, erlang:element(6, Snap)),
    Out@24.

sameLines(A, B) ->
    try
        case (erlang:length(A) =/= erlang:length(B)) of
            true ->
                false;
            _ ->
                I = 0,
                I@3 = (fun __BpLoop(I@1) ->
                    case (I@1 < erlang:length(A)) of
                        true ->
                            case ((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(A, I@1) of
                                undefined ->
                                    <<"">>;
                                __bp_nullish@1 ->
                                    __bp_nullish@1
                            end) =/= (case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(B, I@1) of
                                undefined ->
                                    <<"">>;
                                __bp_nullish ->
                                    __bp_nullish
                            end)) of
                                true ->
                                    erlang:throw({'__bp_try', false});
                                _ -> ok
                            end,
                            I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/records.bp:250:15">>),
                            __BpLoop(I@2);
                        _ -> I@1
                    end
                end)(I),
                true
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

sameRefusal(E, O) ->
    ((((erlang:element(2, E) =:= erlang:element(2, O)) andalso (erlang:element(3, E) =:= erlang:element(3, O))) andalso (erlang:element(4, E) =:= erlang:element(4, O))) andalso sameLines(erlang:element(5, E), erlang:element(5, O))).

%% Whether the observed answer is the accepted one: the refusals, the build

%% lines, the output and the abort equal, and every `stderr` claim contained in

%% `observedStderr`.

matches(Expected, Observed, ObservedStderr) ->
    try
        case (erlang:length(erlang:element(2, Expected)) =/= erlang:length(erlang:element(2, Observed))) of
            true ->
                false;
            _ ->
                I = 0,
                I@3 = (fun __BpLoop(I@1) ->
                    case (I@1 < erlang:length(erlang:element(2, Expected))) of
                        true ->
                            E = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(erlang:element(2, Expected), I@1) of
                                undefined ->
                                    {conformance_lib@records@@Refusal, <<"">>, undefined, undefined, []};
                                __bp_nullish ->
                                    __bp_nullish
                            end,
                            O = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(erlang:element(2, Observed), I@1) of
                                undefined ->
                                    {conformance_lib@records@@Refusal, <<"">>, undefined, undefined, []};
                                __bp_nullish@1 ->
                                    __bp_nullish@1
                            end,
                            case (not sameRefusal(E, O)) of
                                true ->
                                    erlang:throw({'__bp_try', false});
                                _ -> ok
                            end,
                            I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/records.bp:272:15">>),
                            __BpLoop(I@2);
                        _ -> I@1
                    end
                end)(I),
                case (not sameLines(erlang:element(3, Expected), erlang:element(3, Observed))) of
                    true ->
                        false;
                    _ ->
                        case (erlang:element(4, Expected) =/= erlang:element(4, Observed)) of
                            true ->
                                false;
                            _ ->
                                case (erlang:element(5, Expected) =/= erlang:element(5, Observed)) of
                                    true ->
                                        false;
                                    _ ->
                                        array_all(erlang:element(6, Expected), fun(S) ->
                                            (string:find(ObservedStderr, S) =/= nomatch)
                                        end)
                                end
                        end
                end
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

%% The candidate for an observed answer: what it was, plus the accepted file's

%% `stderr` claims that still hold (a candidate never invents one).

candidate(Expected, Observed, ObservedStderr) ->
    Kept = [],
    Kept@3 = case erlang:element(5, Observed) of
        true ->
            Kept@2 = case Expected of
                undefined -> Kept;
                E ->
                    Kept@1 = lists:filter(fun(S) ->
                        (string:find(ObservedStderr, S) =/= nomatch)
                    end, erlang:element(6, E)),
                    Kept@1
            end,
            Kept@2;
        _ ->
            Kept
    end,
    {conformance_lib@records@@Snap, erlang:element(2, Observed), erlang:element(3, Observed), erlang:element(4, Observed), erlang:element(5, Observed), Kept@3}.

splitLines(Text) ->
    case (Text =:= <<"">>) of
        true ->
            [];
        _ ->
            Body = case (fun(__S, __X) -> __N = byte_size(__S), __M = byte_size(__X), (__M =< __N) andalso (binary:part(__S, __N - __M, __M) =:= __X) end)(Text, <<"\n">>) of
                true ->
                    string_slice(Text, 0, '__bp_int'((erlang:length(unicode:characters_to_list(Text)) - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/records.bp:295:35">>));
                false ->
                    Text
            end,
            (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(Body, <<"\n">>)
    end.

%% A line diff of `before` against `after`: `- ` a line only `before` has, `+ `

%% a line only `after` has, `  ` a line both keep (longest common subsequence).

diff(Before, After) ->
    A = splitLines(Before),
    B = splitLines(After),
    % rows[i][j]: the common length of a[i..] and b[j..], built from the last row up.
    Below = array_repeat(0, '__bp_int'((erlang:length(B) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/records.bp:307:49">>)),
    Rows = [Below],
    I = erlang:length(A),
    {I@3, Below@3, Rows@3} = (fun __BpLoop({I@1, Below@1, Rows@1}) ->
        case (I@1 > 0) of
            true ->
                I@2 = '__bp_int'((I@1 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/records.bp:311:15">>),
                Row = [0],
                J = erlang:length(B),
                {J@3, Row@3} = (fun __BpLoop1({J@1, Row@1}) ->
                    case (J@1 > 0) of
                        true ->
                            J@2 = '__bp_int'((J@1 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/records.bp:315:19">>),
                            % `row` holds, reversed, the cells j+1 … b.length of this row.
                            Right = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Row@1, 0) of
                                undefined ->
                                    0;
                                __bp_nullish ->
                                    __bp_nullish
                            end,
                            Cell = case ((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(A, I@2) of
                                undefined ->
                                    <<"">>;
                                __bp_nullish@2 ->
                                    __bp_nullish@2
                            end) =:= (case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(B, J@2) of
                                undefined ->
                                    <<"">>;
                                __bp_nullish@1 ->
                                    __bp_nullish@1
                            end)) of
                                true ->
                                    '__bp_int'(((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Below@1, '__bp_int'((J@2 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/records.bp:319:29">>)) of
                                        undefined ->
                                            0;
                                        __bp_nullish@3 ->
                                            __bp_nullish@3
                                    end) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/records.bp:319:40">>);
                                false ->
                                    case ((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Below@1, J@2) of
                                        undefined ->
                                            0;
                                        __bp_nullish@4 ->
                                            __bp_nullish@4
                                    end) > Right) of
                                        true ->
                                            case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Below@1, J@2) of
                                                undefined ->
                                                    0;
                                                __bp_nullish@5 ->
                                                    __bp_nullish@5
                                            end;
                                        false ->
                                            Right
                                    end
                            end,
                            Row@2 = [Cell | Row@1],
                            __BpLoop1({J@2, Row@2});
                        _ -> {J@1, Row@1}
                    end
                end)({J, Row}),
                Below@2 = Row@3,
                Rows@2 = [Row@3 | Rows@1],
                __BpLoop({I@2, Below@2, Rows@2});
            _ -> {I@1, Below@1, Rows@1}
        end
    end)({I, Below, Rows}),
    Out = <<"">>,
    I@4 = 0,
    J@4 = 0,
    {Out@7, I@10, J@10} = (fun __BpLoop({Out@1, I@5, J@5}) ->
        case ((I@5 < erlang:length(A)) orelse (J@5 < erlang:length(B))) of
            true ->
                Ai = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(A, I@5) of
                    undefined ->
                        <<"">>;
                    __bp_nullish@6 ->
                        __bp_nullish@6
                end,
                Bj = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(B, J@5) of
                    undefined ->
                        <<"">>;
                    __bp_nullish@7 ->
                        __bp_nullish@7
                end,
                {Out@6, I@9, J@9} = case (((I@5 < erlang:length(A)) andalso (J@5 < erlang:length(B))) andalso (Ai =:= Bj)) of
                    true ->
                        Out@2 = <<Out@1/binary, "  ", ('__bp_text'(Ai))/binary, "\n">>,
                        I@6 = '__bp_int'((I@5 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/records.bp:336:19">>),
                        J@6 = '__bp_int'((J@5 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/records.bp:337:19">>),
                        {Out@2, I@6, J@6};
                    _ ->
                        {Out@5, I@8, J@8} = case ((I@5 < erlang:length(A)) andalso (((J@5 =:= erlang:length(B)) orelse (lcs(Rows@3, '__bp_int'((I@5 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/records.bp:339:46">>), J@5) >= lcs(Rows@3, I@5, '__bp_int'((J@5 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/records.bp:339:72">>)))))) of
                            true ->
                                Out@3 = <<Out@1/binary, "- ", ('__bp_text'(Ai))/binary, "\n">>,
                                I@7 = '__bp_int'((I@5 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/records.bp:341:19">>),
                                {Out@3, I@7, J@5};
                            _ ->
                                Out@4 = <<Out@1/binary, "+ ", ('__bp_text'(Bj))/binary, "\n">>,
                                J@7 = '__bp_int'((J@5 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/records.bp:344:19">>),
                                {Out@4, I@5, J@7}
                        end,
                        {Out@5, I@8, J@8}
                end,
                __BpLoop({Out@6, I@9, J@9});
            _ -> {Out@1, I@5, J@5}
        end
    end)({Out, I@4, J@4}),
    Out@7.

lcs(Rows, I, J) ->
    case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Rows, I) of
        undefined ->
            [];
        __bp_nullish ->
            __bp_nullish
    end), J) of
        undefined ->
            0;
        __bp_nullish@1 ->
            __bp_nullish@1
    end.

%% Parse the records of one section's body (no header; an empty body is the empty answer).

%% A malformed body answers its 1-based line within the body and the reason.

parseBody(Body) ->
    try
        Snap = case parse(<<('HEADER'())/binary, "\n", Body/binary>>) of
            {ok, TryV0} -> TryV0;
            {error, M} ->
                case true of
                    _ ->
                        erlang:throw({'__bp_try', {error, {conformance_lib@records@@Malformed, case (erlang:element(2, M) > 1) of
                            true ->
                                '__bp_int'((erlang:element(2, M) - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/records.bp:359:20">>);
                            false ->
                                1
                        end, erlang:element(3, M)}}})
                end
        end,
        {ok, Snap}
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

%% The one spelling of a section's body: `render` without the header line.

renderBody(Snap) ->
    Header = <<('HEADER'())/binary, "\n">>,
    string_slice(render(Snap), erlang:length(unicode:characters_to_list(Header)), undefined).

string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            (fun(__S, __A, __E) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, __F = case __E < 0 of true -> erlang:max(__N + __E, 0); false -> erlang:min(__E, __N) end, unicode:characters_to_binary(lists:sublist(__L, __B + 1, erlang:max(__F - __B, 0))) end)(Self, Start, End);
        false ->
            (fun(__S, __A) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, unicode:characters_to_binary(lists:nthtail(__B, __L)) end)(Self, Start)
    end.

array_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            lists:sublist(Self, (Start) + 1, ((End) - (Start)));
        false ->
            lists:nthtail(Start, Self)
    end.

array_all(Self, Pred) ->
    (erlang:length(lists:filter(Pred, Self)) =:= erlang:length(Self)).

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

'__bp_priv__withAt'(A0, A1) -> withAt(A0, A1).

'__bp_priv__withLabel'(A0, A1) -> withLabel(A0, A1).

'__bp_priv__withFrame'(A0, A1) -> withFrame(A0, A1).

'__bp_priv__record'(A0, A1) -> record(A0, A1).

'__bp_priv__sameLines'(A0, A1) -> sameLines(A0, A1).

'__bp_priv__sameRefusal'(A0, A1) -> sameRefusal(A0, A1).

'__bp_priv__splitLines'(A0) -> splitLines(A0).

'__bp_priv__lcs'(A0, A1, A2) -> lcs(A0, A1, A2).

'__bp_priv__string_slice'(A0, A1, A2) -> string_slice(A0, A1, A2).

'__bp_priv__array_slice'(A0, A1, A2) -> array_slice(A0, A1, A2).

'__bp_priv__array_all'(A0, A1) -> array_all(A0, A1).
