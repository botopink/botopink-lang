-module(std@code).
-export([charAt/2, isDigit/1, isIdentStart/1, isIdentPart/1, isSpace/1, isPair/1, isPunct/1, escaped/1, lexed/2, tokenize/1, ok/2, bad/2, tokAt/2, isP/3, isWord/3, shown/1, expected/3, parseCode/2, expr/3, precedence/1, binary/4, unary/3, postfix/3, callArgs/3, exprList/4, intOf/1, floatOf/1, primary/3, ifExpr/3, lambda/3, fnExpr/3, fnParams/3, statements/3, typeNode/3, arrayType/3, baseType/3, typeList/4, tupleType/3, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__array_slice'/3]).

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

%% behavior Integer

%%% `code`, the template that builds the typed AST from code written with

%%% `${…}` holes (decisions 625 (4), 637, 638, 753).

%%% 

%%% `` code @`Element(tag: ${tag}, kids: [${kids}])` `` reads its text into

%%% `compiler.Node` records and answers what `compiler.ast` builds from them:

%%% code enters the compiler written, never as a string the compiler parses

%%% back (625). Each hole is read by its arrival: a `syntax` value — a

%%% template's receiver, a caller's hole from `compiler.holes(t)`, any

%%% `syntax` parameter — is spliced as it was written (`Syntax(e)`, 638), any

%%% other value as its literal (`Lit(v)`).

%%% 

%%% The text is one expression of the vocabulary `Node` has: a name, a number,

%%% a string, `true` / `false`, a member, a call with positional and labelled

%%% arguments, `[…]`, `#(…)`, the binary operators `|| && == != < > <= >= + -

%%% * / %`, the unary `-` and `!`, `if (c) a else b`, an untyped lambda

%%% `{ a, b -> body }`, and a typed function `fn(a: A) -> R { return …; }`

%%% whose types are the type nodes (753). Anything else — an index, a string

%%% with a hole inside it, a statement other than `return` or an expression —

%%% is refused at the template's call, naming what was met.

%%% 

%%% Imported where used: `import {code} from "std";`.

%% import Node, Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType

% ── The tokens ──────────────────────────────────────────────────────────────

% `kind` one of `name`, `int`, `float`, `str`, `punct`, `hole`, `eof`; `hole`

% the hole's index for a `hole`, a number's value its `text`.

%% type Tok: kind, text, hole

%% type Lexed: toks, err

charAt(Cs, I) ->
    case (I < 0) of
        true ->
            <<"">>;
        _ ->
            case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cs, I) of
                undefined ->
                    <<"">>;
                __bp_nullish ->
                    __bp_nullish
            end
    end.

isDigit(C) ->
    ((C =/= <<"">>) andalso (string:find(<<"0123456789">>, C) =/= nomatch)).

isIdentStart(C) ->
    ((C =/= <<"">>) andalso (string:find(<<"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_">>, C) =/= nomatch)).

isIdentPart(C) ->
    (isIdentStart(C) orelse isDigit(C)).

isSpace(C) ->
    ((((C =:= <<" ">>) orelse (C =:= <<"\n">>)) orelse (C =:= <<"\t">>)) orelse (C =:= <<"\r">>)).

% The two-character operators; every other punctuation is one character.

isPair(Two) ->
    ((((((((Two =:= <<"->">>) orelse (Two =:= <<"==">>)) orelse (Two =:= <<"!=">>)) orelse (Two =:= <<"<=">>)) orelse (Two =:= <<">=">>)) orelse (Two =:= <<"&&">>)) orelse (Two =:= <<"||">>)) orelse (Two =:= <<"??">>)).

isPunct(C) ->
    ((C =/= <<"">>) andalso (string:find(<<"()[]{},.:;+-*/%<>!#?|=">>, C) =/= nomatch)).

escaped(C) ->
    case (C =:= <<"n">>) of
        true ->
            <<"\n">>;
        _ ->
            case (C =:= <<"t">>) of
                true ->
                    <<"\t">>;
                _ ->
                    case (C =:= <<"r">>) of
                        true ->
                            <<"\r">>;
                        _ ->
                            case (C =:= <<"0">>) of
                                true ->
                                    <<(0)/utf8>>;
                                _ ->
                                    C
                            end
                    end
            end
    end.

lexed(Toks, Err) ->
    {std@code@@Lexed, Toks, Err}.

% The text's tokens, a hole `${…}` one token (its braces nest, a string's do

% not count — as the compiler finds the holes `compiler.holes` answers).

tokenize(Text) ->
    Cs = [<<__C/utf8>> || __C <- unicode:characters_to_list(Text, utf8)],
    Toks = [],
    I = 0,
    Hole = 0,
    Err = <<"">>,
    {I@21, Err@21, Toks@17, Hole@7} = (fun __BpLoop({I@1, Err@1, Toks@1, Hole@1}) ->
        case ((Err@1 =:= <<"">>) andalso (I@1 < erlang:length(Cs))) of
            true ->
                C = charAt(Cs, I@1),
                Next = charAt(Cs, '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:107:33">>)),
                {I@20, Err@20, Toks@16, Hole@6} = case isSpace(C) of
                    true ->
                        I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:109:19">>),
                        {I@2, Err@1, Toks@1, Hole@1};
                    _ ->
                        {I@19, Err@19, Toks@15, Hole@5} = case ((C =:= <<"/">>) andalso (Next =:= <<"/">>)) of
                            true ->
                                I@5 = (fun __BpLoop1(I@3) ->
                                    case ((I@3 < erlang:length(Cs)) andalso (charAt(Cs, I@3) =/= <<"\n">>)) of
                                        true ->
                                            I@4 = '__bp_int'((I@3 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:112:23">>),
                                            __BpLoop1(I@4);
                                        _ -> I@3
                                    end
                                end)(I@1),
                                {I@5, Err@1, Toks@1, Hole@1};
                            _ ->
                                {Err@18, Toks@14, Hole@4, I@18} = case ((C =:= <<"$">>) andalso (Next =:= <<"{">>)) of
                                    true ->
                                        Depth = 1,
                                        J = '__bp_int'((I@1 + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:116:23">>),
                                        Quoted = false,
                                        {J@6, Quoted@8, Depth@8} = (fun __BpLoop1({J@1, Quoted@1, Depth@1}) ->
                                            case ((Depth@1 > 0) andalso (J@1 < erlang:length(Cs))) of
                                                true ->
                                                    D = charAt(Cs, J@1),
                                                    {J@4, Quoted@7, Depth@7} = case Quoted@1 of
                                                        true ->
                                                            {J@3, Quoted@4} = case (D =:= <<"\\">>) of
                                                                true ->
                                                                    J@2 = '__bp_int'((J@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:121:42">>),
                                                                    {J@2, Quoted@1};
                                                                _ ->
                                                                    Quoted@3 = case (D =:= <<"\"">>) of
                                                                        true ->
                                                                            Quoted@2 = false,
                                                                            Quoted@2;
                                                                        _ ->
                                                                            Quoted@1
                                                                    end,
                                                                    {J@1, Quoted@3}
                                                            end,
                                                            {J@3, Quoted@4, Depth@1};
                                                        _ ->
                                                            {Quoted@6, Depth@6} = case (D =:= <<"\"">>) of
                                                                true ->
                                                                    Quoted@5 = true,
                                                                    {Quoted@5, Depth@1};
                                                                _ ->
                                                                    Depth@5 = case (D =:= <<"{">>) of
                                                                        true ->
                                                                            Depth@2 = '__bp_int'((Depth@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:125:35">>),
                                                                            Depth@2;
                                                                        _ ->
                                                                            Depth@4 = case (D =:= <<"}">>) of
                                                                                true ->
                                                                                    Depth@3 = '__bp_int'((Depth@1 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/code.bp:127:35">>),
                                                                                    Depth@3;
                                                                                _ ->
                                                                                    Depth@1
                                                                            end,
                                                                            Depth@4
                                                                    end,
                                                                    {Quoted@1, Depth@5}
                                                            end,
                                                            {J@1, Quoted@6, Depth@6}
                                                    end,
                                                    J@5 = '__bp_int'((J@4 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:128:23">>),
                                                    __BpLoop1({J@5, Quoted@7, Depth@7});
                                                _ -> {J@1, Quoted@1, Depth@1}
                                            end
                                        end)({J, Quoted, Depth}),
                                        {Err@3, Toks@3, Hole@3, I@7} = case (Depth@8 > 0) of
                                            true ->
                                                Err@2 = <<"a `${` with no closing `}`">>,
                                                {Err@2, Toks@1, Hole@1, I@1};
                                            _ ->
                                                Toks@2 = (Toks@1 ++ [{std@code@@Tok, <<"hole">>, <<"">>, Hole@1}]),
                                                Hole@2 = '__bp_int'((Hole@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:132:29">>),
                                                I@6 = J@6,
                                                {Err@1, Toks@2, Hole@2, I@6}
                                        end,
                                        {Err@3, Toks@3, Hole@3, I@7};
                                    _ ->
                                        {Toks@13, I@17, Err@17} = case isIdentStart(C) of
                                            true ->
                                                J@7 = I@1,
                                                J@10 = (fun __BpLoop1(J@8) ->
                                                    case isIdentPart(charAt(Cs, J@8)) of
                                                        true ->
                                                            J@9 = '__bp_int'((J@8 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:138:23">>),
                                                            __BpLoop1(J@9);
                                                        _ -> J@8
                                                    end
                                                end)(J@7),
                                                Toks@4 = (Toks@1 ++ [{std@code@@Tok, <<"name">>, iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, array_slice(Cs, I@1, J@10)))), 0}]),
                                                I@8 = J@10,
                                                {Toks@4, I@8, Err@1};
                                            _ ->
                                                {Toks@12, I@16, Err@16} = case isDigit(C) of
                                                    true ->
                                                        J@11 = I@1,
                                                        J@14 = (fun __BpLoop1(J@12) ->
                                                            case (isDigit(charAt(Cs, J@12)) orelse (charAt(Cs, J@12) =:= <<"_">>)) of
                                                                true ->
                                                                    J@13 = '__bp_int'((J@12 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:147:23">>),
                                                                    __BpLoop1(J@13);
                                                                _ -> J@12
                                                            end
                                                        end)(J@11),
                                                        Kind = <<"int">>,
                                                        {Kind@2, J@19} = case ((charAt(Cs, J@14) =:= <<".">>) andalso isDigit(charAt(Cs, '__bp_int'((J@14 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:150:62">>)))) of
                                                            true ->
                                                                Kind@1 = <<"float">>,
                                                                J@15 = '__bp_int'((J@14 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:152:23">>),
                                                                J@18 = (fun __BpLoop1(J@16) ->
                                                                    case (isDigit(charAt(Cs, J@16)) orelse (charAt(Cs, J@16) =:= <<"_">>)) of
                                                                        true ->
                                                                            J@17 = '__bp_int'((J@16 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:154:27">>),
                                                                            __BpLoop1(J@17);
                                                                        _ -> J@16
                                                                    end
                                                                end)(J@15),
                                                                {Kind@1, J@18};
                                                            _ ->
                                                                {Kind, J@14}
                                                        end,
                                                        Toks@5 = (Toks@1 ++ [{std@code@@Tok, Kind@2, (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, array_slice(Cs, I@1, J@19)))), <<"_">>, <<"">>), 0}]),
                                                        I@9 = J@19,
                                                        {Toks@5, I@9, Err@1};
                                                    _ ->
                                                        {Err@15, Toks@11, I@15} = case (C =:= <<"\"">>) of
                                                            true ->
                                                                J@20 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:163:23">>),
                                                                Value = <<"">>,
                                                                Closed = false,
                                                                {Closed@4, Value@7, J@26, Err@9} = (fun __BpLoop1({Closed@1, Value@1, J@21, Err@4}) ->
                                                                    case (((Err@4 =:= <<"">>) andalso (not Closed@1)) andalso (J@21 < erlang:length(Cs))) of
                                                                        true ->
                                                                            D@1 = charAt(Cs, J@21),
                                                                            {Closed@3, Value@6, J@24, Err@8} = case (D@1 =:= <<"\"">>) of
                                                                                true ->
                                                                                    Closed@2 = true,
                                                                                    {Closed@2, Value@1, J@21, Err@4};
                                                                                _ ->
                                                                                    {Value@5, J@23, Err@7} = case (D@1 =:= <<"\\">>) of
                                                                                        true ->
                                                                                            Value@2 = <<Value@1/binary, (escaped(charAt(Cs, '__bp_int'((J@21 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:169:58">>))))/binary>>,
                                                                                            J@22 = '__bp_int'((J@21 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:170:27">>),
                                                                                            {Value@2, J@22, Err@4};
                                                                                        _ ->
                                                                                            {Err@6, Value@4} = case ((D@1 =:= <<"$">>) andalso (charAt(Cs, '__bp_int'((J@21 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:171:53">>)) =:= <<"{">>)) of
                                                                                                true ->
                                                                                                    Err@5 = <<"a hole inside a string literal: write the string and the hole apart, `\"a\" + ${x}`">>,
                                                                                                    {Err@5, Value@1};
                                                                                                _ ->
                                                                                                    Value@3 = <<Value@1/binary, D@1/binary>>,
                                                                                                    {Err@4, Value@3}
                                                                                            end,
                                                                                            {Value@4, J@21, Err@6}
                                                                                    end,
                                                                                    {Closed@1, Value@5, J@23, Err@7}
                                                                            end,
                                                                            J@25 = '__bp_int'((J@24 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:175:23">>),
                                                                            __BpLoop1({Closed@3, Value@6, J@25, Err@8});
                                                                        _ -> {Closed@1, Value@1, J@21, Err@4}
                                                                    end
                                                                end)({Closed, Value, J@20, Err@1}),
                                                                Err@11 = case ((Err@9 =:= <<"">>) andalso (not Closed@4)) of
                                                                    true ->
                                                                        Err@10 = <<"a string literal with no closing `\"`">>,
                                                                        Err@10;
                                                                    _ ->
                                                                        Err@9
                                                                end,
                                                                Toks@6 = (Toks@1 ++ [{std@code@@Tok, <<"str">>, Value@7, 0}]),
                                                                I@10 = J@26,
                                                                {Err@11, Toks@6, I@10};
                                                            _ ->
                                                                {Toks@10, I@14, Err@14} = case isPair(<<C/binary, Next/binary>>) of
                                                                    true ->
                                                                        Toks@7 = (Toks@1 ++ [{std@code@@Tok, <<"punct">>, <<C/binary, Next/binary>>, 0}]),
                                                                        I@11 = '__bp_int'((I@1 + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:183:19">>),
                                                                        {Toks@7, I@11, Err@1};
                                                                    _ ->
                                                                        {Toks@9, I@13, Err@13} = case isPunct(C) of
                                                                            true ->
                                                                                Toks@8 = (Toks@1 ++ [{std@code@@Tok, <<"punct">>, C, 0}]),
                                                                                I@12 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:186:19">>),
                                                                                {Toks@8, I@12, Err@1};
                                                                            _ ->
                                                                                Err@12 = <<"`", C/binary, "` is no token of the language">>,
                                                                                {Toks@1, I@1, Err@12}
                                                                        end,
                                                                        {Toks@9, I@13, Err@13}
                                                                end,
                                                                {Err@14, Toks@10, I@14}
                                                        end,
                                                        {Toks@11, I@15, Err@15}
                                                end,
                                                {Toks@12, I@16, Err@16}
                                        end,
                                        {Err@17, Toks@13, Hole@1, I@17}
                                end,
                                {I@18, Err@18, Toks@14, Hole@4}
                        end,
                        {I@19, Err@19, Toks@15, Hole@5}
                end,
                __BpLoop({I@20, Err@20, Toks@16, Hole@6});
            _ -> {I@1, Err@1, Toks@1, Hole@1}
        end
    end)({I, Err, Toks, Hole}),
    Toks@18 = (Toks@17 ++ [{std@code@@Tok, <<"eof">>, <<"">>, 0}]),
    lexed(Toks@18, Err@21).

% ── The parser ──────────────────────────────────────────────────────────────

% A node read and the index of the token after it; `err` the reason the text

% is no code of `Node`'s vocabulary, empty when it is.

%% type P: node, pos, err

% Nodes read and the index of the token after them.

%% type Ps: nodes, pos, err

%% type Params: params, pos, err

ok(Node, Pos) ->
    {std@code@@P, Node, Pos, <<"">>}.

bad(Err, Pos) ->
    {std@code@@P, {std@compiler@@Lit, 0}, Pos, Err}.

tokAt(Ts, I) ->
    case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Ts, I) of
        undefined ->
            {std@code@@Tok, <<"eof">>, <<"">>, 0};
        __bp_nullish ->
            __bp_nullish
    end.

isP(Ts, I, Text) ->
    T = tokAt(Ts, I),
    ((erlang:element(2, T) =:= <<"punct">>) andalso (erlang:element(3, T) =:= Text)).

isWord(Ts, I, Word) ->
    T = tokAt(Ts, I),
    ((erlang:element(2, T) =:= <<"name">>) andalso (erlang:element(3, T) =:= Word)).

shown(T) ->
    case (erlang:element(2, T) =:= <<"eof">>) of
        true ->
            <<"the end of the text">>;
        _ ->
            case (erlang:element(2, T) =:= <<"hole">>) of
                true ->
                    <<"a hole">>;
                _ ->
                    case (erlang:element(2, T) =:= <<"str">>) of
                        true ->
                            <<"a string">>;
                        _ ->
                            <<"`", ('__bp_text'(erlang:element(3, T)))/binary, "`">>
                    end
            end
    end.

expected(Ts, I, What) ->
    bad(<<"expected ", What/binary, ", found ", (shown(tokAt(Ts, I)))/binary>>, I).

parseCode(Text, Holes) ->
    Lx = tokenize(Text),
    case (erlang:element(3, Lx) =/= <<"">>) of
        true ->
            bad(erlang:element(3, Lx), 0);
        _ ->
            P = expr(erlang:element(2, Lx), 0, Holes),
            case (erlang:element(4, P) =/= <<"">>) of
                true ->
                    P;
                _ ->
                    case (erlang:element(2, tokAt(erlang:element(2, Lx), erlang:element(3, P))) =/= <<"eof">>) of
                        true ->
                            expected(erlang:element(2, Lx), erlang:element(3, P), <<"the end of the expression">>);
                        _ ->
                            P
                    end
            end
    end.

expr(Ts, I, Holes) ->
    binary(Ts, I, Holes, 1).

% The precedence of a binary operator, 0 for a token that is none.

precedence(T) ->
    case (erlang:element(2, T) =/= <<"punct">>) of
        true ->
            0;
        _ ->
            Op = erlang:element(3, T),
            case (Op =:= <<"||">>) of
                true ->
                    1;
                _ ->
                    case (Op =:= <<"&&">>) of
                        true ->
                            2;
                        _ ->
                            case ((Op =:= <<"==">>) orelse (Op =:= <<"!=">>)) of
                                true ->
                                    3;
                                _ ->
                                    case ((((Op =:= <<"<">>) orelse (Op =:= <<">">>)) orelse (Op =:= <<"<=">>)) orelse (Op =:= <<">=">>)) of
                                        true ->
                                            4;
                                        _ ->
                                            case ((Op =:= <<"+">>) orelse (Op =:= <<"-">>)) of
                                                true ->
                                                    5;
                                                _ ->
                                                    case (((Op =:= <<"*">>) orelse (Op =:= <<"/">>)) orelse (Op =:= <<"%">>)) of
                                                        true ->
                                                            6;
                                                        _ ->
                                                            0
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end.

binary(Ts, I, Holes, Least) ->
    Left = unary(Ts, I, Holes),
    Going = (erlang:element(4, Left) =:= <<"">>),
    {Going@6, Left@6} = (fun __BpLoop({Going@1, Left@1}) ->
        case Going@1 of
            true ->
                T = tokAt(Ts, erlang:element(3, Left@1)),
                Prec = precedence(T),
                {Going@5, Left@5} = case ((Prec =:= 0) orelse (Prec < Least)) of
                    true ->
                        Going@2 = false,
                        {Going@2, Left@1};
                    _ ->
                        Right = binary(Ts, '__bp_int'((erlang:element(3, Left@1) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:271:45">>), Holes, '__bp_int'((Prec + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:271:62">>)),
                        {Left@4, Going@4} = case (erlang:element(4, Right) =/= <<"">>) of
                            true ->
                                Left@2 = Right,
                                Going@3 = false,
                                {Left@2, Going@3};
                            _ ->
                                Left@3 = ok({std@compiler@@Binary, erlang:element(3, T), erlang:element(2, Left@1), erlang:element(2, Right)}, erlang:element(3, Right)),
                                {Left@3, Going@1}
                        end,
                        {Going@4, Left@4}
                end,
                __BpLoop({Going@5, Left@5});
            _ -> {Going@1, Left@1}
        end
    end)({Going, Left}),
    Left@6.

unary(Ts, I, Holes) ->
    case (isP(Ts, I, <<"-">>) orelse isP(Ts, I, <<"!">>)) of
        true ->
            Operand = unary(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:283:35">>), Holes),
            case (erlang:element(4, Operand) =/= <<"">>) of
                true ->
                    Operand;
                _ ->
                    ok({std@compiler@@Unary, erlang:element(3, tokAt(Ts, I)), erlang:element(2, Operand)}, erlang:element(3, Operand))
            end;
        _ ->
            postfix(Ts, I, Holes)
    end.

postfix(Ts, I, Holes) ->
    Cur = primary(Ts, I, Holes),
    Going = (erlang:element(4, Cur) =:= <<"">>),
    {Cur@10, Going@9} = (fun __BpLoop({Cur@1, Going@1}) ->
        case Going@1 of
            true ->
                {Cur@9, Going@8} = case isP(Ts, erlang:element(3, Cur@1), <<".">>) of
                    true ->
                        T = tokAt(Ts, '__bp_int'((erlang:element(3, Cur@1) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:295:39">>)),
                        {Cur@4, Going@3} = case (erlang:element(2, T) =/= <<"name">>) of
                            true ->
                                Cur@2 = expected(Ts, '__bp_int'((erlang:element(3, Cur@1) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:297:44">>), <<"a member name after `.`">>),
                                Going@2 = false,
                                {Cur@2, Going@2};
                            _ ->
                                Cur@3 = ok({std@compiler@@Member, erlang:element(2, Cur@1), erlang:element(3, T)}, '__bp_int'((erlang:element(3, Cur@1) + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:300:17">>)),
                                {Cur@3, Going@1}
                        end,
                        {Cur@4, Going@3};
                    _ ->
                        {Cur@8, Going@7} = case isP(Ts, erlang:element(3, Cur@1), <<"(">>) of
                            true ->
                                Args = callArgs(Ts, '__bp_int'((erlang:element(3, Cur@1) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:302:45">>), Holes),
                                {Cur@7, Going@5} = case (erlang:element(4, Args) =/= <<"">>) of
                                    true ->
                                        Cur@5 = bad(erlang:element(4, Args), erlang:element(3, Args)),
                                        Going@4 = false,
                                        {Cur@5, Going@4};
                                    _ ->
                                        Cur@6 = ok({std@compiler@@Call, erlang:element(2, Cur@1), erlang:element(2, Args)}, erlang:element(3, Args)),
                                        {Cur@6, Going@1}
                                end,
                                {Cur@7, Going@5};
                            _ ->
                                Going@6 = false,
                                {Cur@1, Going@6}
                        end,
                        {Cur@8, Going@7}
                end,
                __BpLoop({Cur@9, Going@8});
            _ -> {Cur@1, Going@1}
        end
    end)({Cur, Going}),
    Cur@10.

% A call's arguments after its `(`, up to and past its `)`: `name: value` an

% `Arg`, any other a positional node.

callArgs(Ts, I, Holes) ->
    Out = [],
    Pos = I,
    Err = <<"">>,
    {Err@7, Pos@7, Out@6} = (fun __BpLoop({Err@1, Pos@1, Out@1}) ->
        case ((Err@1 =:= <<"">>) andalso (not isP(Ts, Pos@1, <<")">>))) of
            true ->
                Labelled = ((erlang:element(2, tokAt(Ts, Pos@1)) =:= <<"name">>) andalso isP(Ts, '__bp_int'((Pos@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:319:69">>), <<":">>)),
                Start = case Labelled of
                    true ->
                        '__bp_int'((Pos@1 + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:320:39">>);
                    false ->
                        Pos@1
                end,
                V = expr(Ts, Start, Holes),
                {Err@6, Pos@6, Out@5} = case (erlang:element(4, V) =/= <<"">>) of
                    true ->
                        Err@2 = erlang:element(4, V),
                        Pos@2 = erlang:element(3, V),
                        {Err@2, Pos@2, Out@1};
                    _ ->
                        Out@4 = case Labelled of
                            true ->
                                Out@2 = (Out@1 ++ [{std@compiler@@Arg, erlang:element(3, tokAt(Ts, Pos@1)), erlang:element(2, V)}]),
                                Out@2;
                            _ ->
                                Out@3 = (Out@1 ++ [erlang:element(2, V)]),
                                Out@3
                        end,
                        Pos@3 = erlang:element(3, V),
                        {Pos@5, Err@5} = case isP(Ts, Pos@3, <<",">>) of
                            true ->
                                Pos@4 = '__bp_int'((Pos@3 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:332:27">>),
                                {Pos@4, Err@1};
                            _ ->
                                Err@4 = case (not isP(Ts, Pos@3, <<")">>)) of
                                    true ->
                                        Err@3 = erlang:element(4, expected(Ts, Pos@3, <<"`,` or `)`">>)),
                                        Err@3;
                                    _ ->
                                        Err@1
                                end,
                                {Pos@3, Err@4}
                        end,
                        {Err@5, Pos@5, Out@4}
                end,
                __BpLoop({Err@6, Pos@6, Out@5});
            _ -> {Err@1, Pos@1, Out@1}
        end
    end)({Err, Pos, Out}),
    case (Err@7 =/= <<"">>) of
        true ->
            {std@code@@Ps, Out@6, Pos@7, Err@7};
        _ ->
            {std@code@@Ps, Out@6, '__bp_int'((Pos@7 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:338:36">>), <<"">>}
    end.

% Expressions separated by `,` up to and past `close`.

exprList(Ts, I, Holes, Close) ->
    Out = [],
    Pos = I,
    Err = <<"">>,
    {Err@7, Pos@7, Out@4} = (fun __BpLoop({Err@1, Pos@1, Out@1}) ->
        case ((Err@1 =:= <<"">>) andalso (not isP(Ts, Pos@1, Close))) of
            true ->
                V = expr(Ts, Pos@1, Holes),
                {Err@6, Pos@6, Out@3} = case (erlang:element(4, V) =/= <<"">>) of
                    true ->
                        Err@2 = erlang:element(4, V),
                        Pos@2 = erlang:element(3, V),
                        {Err@2, Pos@2, Out@1};
                    _ ->
                        Out@2 = (Out@1 ++ [erlang:element(2, V)]),
                        Pos@3 = erlang:element(3, V),
                        {Pos@5, Err@5} = case isP(Ts, Pos@3, <<",">>) of
                            true ->
                                Pos@4 = '__bp_int'((Pos@3 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:355:27">>),
                                {Pos@4, Err@1};
                            _ ->
                                Err@4 = case (not isP(Ts, Pos@3, Close)) of
                                    true ->
                                        Err@3 = erlang:element(4, expected(Ts, Pos@3, <<"`,` or `", Close/binary, "`">>)),
                                        Err@3;
                                    _ ->
                                        Err@1
                                end,
                                {Pos@3, Err@4}
                        end,
                        {Err@5, Pos@5, Out@2}
                end,
                __BpLoop({Err@6, Pos@6, Out@3});
            _ -> {Err@1, Pos@1, Out@1}
        end
    end)({Err, Pos, Out}),
    case (Err@7 =/= <<"">>) of
        true ->
            {std@code@@Ps, Out@4, Pos@7, Err@7};
        _ ->
            {std@code@@Ps, Out@4, '__bp_int'((Pos@7 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:361:36">>), <<"">>}
    end.

intOf(Text) ->
    Cs = [<<__C/utf8>> || __C <- unicode:characters_to_list(Text, utf8)],
    N = 0,
    I = 0,
    {N@3, I@3} = (fun __BpLoop({N@1, I@1}) ->
        case (I@1 < erlang:length(Cs)) of
            true ->
                N@2 = '__bp_int'(('__bp_int'((N@1 * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/code.bp:369:15">>) + ('__bp_int'(((fun(__S, __I) -> case unicode:characters_to_list(__S, utf8) of __L when length(__L) > __I, __I >= 0 -> lists:nth(__I + 1, __L); _ -> -1 end end)(charAt(Cs, I@1), 0) - 48), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/code.bp:369:51">>))), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:369:20">>),
                I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:370:15">>),
                __BpLoop({N@2, I@2});
            _ -> {N@1, I@1}
        end
    end)({N, I}),
    N@3.

floatOf(Text) ->
    Parts = (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(Text, <<".">>),
    Whole = intOf(case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Parts, 0) of
        undefined ->
            <<"0">>;
        __bp_nullish ->
            __bp_nullish
    end),
    Frac = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Parts, 1) of
        undefined ->
            <<"0">>;
        __bp_nullish@1 ->
            __bp_nullish@1
    end,
    Scale = 1.0,
    I = 0,
    {Scale@3, I@3} = (fun __BpLoop({Scale@1, I@1}) ->
        case (I@1 < erlang:length(unicode:characters_to_list(Frac))) of
            true ->
                Scale@2 = (Scale@1 * 10.0),
                I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:383:15">>),
                __BpLoop({Scale@2, I@2});
            _ -> {Scale@1, I@1}
        end
    end)({Scale, I}),
    ((fun(__V) -> __F = float(__V), case trunc(__F) =:= __V of true -> __F; false -> erlang:error({integer_overflow, <<"toF64: ", (integer_to_binary(__V))/binary, " has no exact f64">>}) end end)(Whole) + ((fun(__V) -> __F = float(__V), case trunc(__F) =:= __V of true -> __F; false -> erlang:error({integer_overflow, <<"toF64: ", (integer_to_binary(__V))/binary, " has no exact f64">>}) end end)(intOf(Frac)) / '__bp_nz'(Scale@3, <<"division by zero: / on f64 at src/code.bp:385:48">>))).

primary(Ts, I, Holes) ->
    T = tokAt(Ts, I),
    case (erlang:element(2, T) =:= <<"hole">>) of
        true ->
            ok(case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Holes, erlang:element(4, T)) of
                undefined ->
                    {std@compiler@@Lit, 0};
                __bp_nullish ->
                    __bp_nullish
            end, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:390:67">>));
        _ ->
            case (erlang:element(2, T) =:= <<"int">>) of
                true ->
                    ok({std@compiler@@Lit, intOf(erlang:element(3, T))}, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:391:58">>));
                _ ->
                    case (erlang:element(2, T) =:= <<"float">>) of
                        true ->
                            ok({std@compiler@@Lit, floatOf(erlang:element(3, T))}, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:392:62">>));
                        _ ->
                            case (erlang:element(2, T) =:= <<"str">>) of
                                true ->
                                    ok({std@compiler@@Lit, erlang:element(3, T)}, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:393:51">>));
                                _ ->
                                    case (erlang:element(2, T) =:= <<"name">>) of
                                        true ->
                                            case (erlang:element(3, T) =:= <<"true">>) of
                                                true ->
                                                    ok({std@compiler@@Lit, true}, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:395:54">>));
                                                _ ->
                                                    case (erlang:element(3, T) =:= <<"false">>) of
                                                        true ->
                                                            ok({std@compiler@@Lit, false}, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:396:56">>));
                                                        _ ->
                                                            case (erlang:element(3, T) =:= <<"if">>) of
                                                                true ->
                                                                    ifExpr(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:397:49">>), Holes);
                                                                _ ->
                                                                    case (erlang:element(3, T) =:= <<"fn">>) of
                                                                        true ->
                                                                            fnExpr(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:398:49">>), Holes);
                                                                        _ ->
                                                                            ok({std@compiler@@Name, erlang:element(3, T)}, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:399:35">>))
                                                                    end
                                                            end
                                                    end
                                            end;
                                        _ ->
                                            case isP(Ts, I, <<"(">>) of
                                                true ->
                                                    Inner = expr(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:402:32">>), Holes),
                                                    case (erlang:element(4, Inner) =/= <<"">>) of
                                                        true ->
                                                            Inner;
                                                        _ ->
                                                            case (not isP(Ts, erlang:element(3, Inner), <<")">>)) of
                                                                true ->
                                                                    expected(Ts, erlang:element(3, Inner), <<"`)`">>);
                                                                _ ->
                                                                    ok(erlang:element(2, Inner), '__bp_int'((erlang:element(3, Inner) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:405:41">>))
                                                            end
                                                    end;
                                                _ ->
                                                    case isP(Ts, I, <<"[">>) of
                                                        true ->
                                                            Items = exprList(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:408:36">>), Holes, <<"]">>),
                                                            case (erlang:element(4, Items) =/= <<"">>) of
                                                                true ->
                                                                    bad(erlang:element(4, Items), erlang:element(3, Items));
                                                                _ ->
                                                                    ok({std@compiler@@List, erlang:element(2, Items)}, erlang:element(3, Items))
                                                            end;
                                                        _ ->
                                                            case (isP(Ts, I, <<"#">>) andalso isP(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:412:38">>), <<"(">>)) of
                                                                true ->
                                                                    Elems = exprList(Ts, '__bp_int'((I + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:413:36">>), Holes, <<")">>),
                                                                    case (erlang:element(4, Elems) =/= <<"">>) of
                                                                        true ->
                                                                            bad(erlang:element(4, Elems), erlang:element(3, Elems));
                                                                        _ ->
                                                                            ok({std@compiler@@Tuple, erlang:element(2, Elems)}, erlang:element(3, Elems))
                                                                    end;
                                                                _ ->
                                                                    case isP(Ts, I, <<"{">>) of
                                                                        true ->
                                                                            lambda(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:417:46">>), Holes);
                                                                        _ ->
                                                                            expected(Ts, I, <<"an expression">>)
                                                                    end
                                                            end
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end.

% `if (cond) then else otherwise`, after its `if`.

ifExpr(Ts, I, Holes) ->
    case (not isP(Ts, I, <<"(">>)) of
        true ->
            expected(Ts, I, <<"`(` after `if`">>);
        _ ->
            Cond = expr(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:424:27">>), Holes),
            case (erlang:element(4, Cond) =/= <<"">>) of
                true ->
                    Cond;
                _ ->
                    case (not isP(Ts, erlang:element(3, Cond), <<")">>)) of
                        true ->
                            expected(Ts, erlang:element(3, Cond), <<"`)`">>);
                        _ ->
                            Then = expr(Ts, '__bp_int'((erlang:element(3, Cond) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:427:34">>), Holes),
                            case (erlang:element(4, Then) =/= <<"">>) of
                                true ->
                                    Then;
                                _ ->
                                    case (not isWord(Ts, erlang:element(3, Then), <<"else">>)) of
                                        true ->
                                            expected(Ts, erlang:element(3, Then), <<"`else`: an `if` that answers a value has both branches">>);
                                        _ ->
                                            Otherwise = expr(Ts, '__bp_int'((erlang:element(3, Then) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:431:39">>), Holes),
                                            case (erlang:element(4, Otherwise) =/= <<"">>) of
                                                true ->
                                                    Otherwise;
                                                _ ->
                                                    ok({std@compiler@@If, erlang:element(2, Cond), erlang:element(2, Then), erlang:element(2, Otherwise)}, erlang:element(3, Otherwise))
                                            end
                                    end
                            end
                    end
            end
    end.

% `{ a, b -> body }` (or `{ -> body }`), after its `{`.

lambda(Ts, I, Holes) ->
    Names = [],
    Pos = I,
    Err = <<"">>,
    {Err@7, Names@4, Pos@6} = (fun __BpLoop({Err@1, Names@1, Pos@1}) ->
        case ((Err@1 =:= <<"">>) andalso (not isP(Ts, Pos@1, <<"->">>))) of
            true ->
                T = tokAt(Ts, Pos@1),
                {Err@6, Names@3, Pos@5} = case (erlang:element(2, T) =/= <<"name">>) of
                    true ->
                        Err@2 = erlang:element(4, expected(Ts, Pos@1, <<"a parameter name or `->`">>)),
                        {Err@2, Names@1, Pos@1};
                    _ ->
                        Names@2 = (Names@1 ++ [erlang:element(3, T)]),
                        Pos@2 = '__bp_int'((Pos@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:447:23">>),
                        {Pos@4, Err@5} = case isP(Ts, Pos@2, <<",">>) of
                            true ->
                                Pos@3 = '__bp_int'((Pos@2 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:449:27">>),
                                {Pos@3, Err@1};
                            _ ->
                                Err@4 = case (not isP(Ts, Pos@2, <<"->">>)) of
                                    true ->
                                        Err@3 = erlang:element(4, expected(Ts, Pos@2, <<"`,` or `->`">>)),
                                        Err@3;
                                    _ ->
                                        Err@1
                                end,
                                {Pos@2, Err@4}
                        end,
                        {Err@5, Names@2, Pos@4}
                end,
                __BpLoop({Err@6, Names@3, Pos@5});
            _ -> {Err@1, Names@1, Pos@1}
        end
    end)({Err, Names, Pos}),
    case (Err@7 =/= <<"">>) of
        true ->
            bad(Err@7, Pos@6);
        _ ->
            Body = expr(Ts, '__bp_int'((Pos@6 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:455:29">>), Holes),
            case (erlang:element(4, Body) =/= <<"">>) of
                true ->
                    Body;
                _ ->
                    case (not isP(Ts, erlang:element(3, Body), <<"}">>)) of
                        true ->
                            expected(Ts, erlang:element(3, Body), <<"`}`">>);
                        _ ->
                            ok({std@compiler@@Lambda, Names@4, erlang:element(2, Body)}, '__bp_int'((erlang:element(3, Body) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:458:64">>))
                    end
            end
    end.

% `fn(a: A, b: B) -> R { statements }`, after its `fn` (decision 753).

fnExpr(Ts, I, Holes) ->
    case (not isP(Ts, I, <<"(">>)) of
        true ->
            expected(Ts, I, <<"`(` after `fn`">>);
        _ ->
            Ps = fnParams(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:464:29">>), Holes),
            case (erlang:element(4, Ps) =/= <<"">>) of
                true ->
                    bad(erlang:element(4, Ps), erlang:element(3, Ps));
                _ ->
                    case (not isP(Ts, erlang:element(3, Ps), <<"->">>)) of
                        true ->
                            expected(Ts, erlang:element(3, Ps), <<"`->` and the return type">>);
                        _ ->
                            Ret = typeNode(Ts, '__bp_int'((erlang:element(3, Ps) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:468:35">>), Holes),
                            case (erlang:element(4, Ret) =/= <<"">>) of
                                true ->
                                    Ret;
                                _ ->
                                    case (not isP(Ts, erlang:element(3, Ret), <<"{">>)) of
                                        true ->
                                            expected(Ts, erlang:element(3, Ret), <<"`{`">>);
                                        _ ->
                                            Body = statements(Ts, '__bp_int'((erlang:element(3, Ret) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:471:39">>), Holes),
                                            case (erlang:element(4, Body) =/= <<"">>) of
                                                true ->
                                                    bad(erlang:element(4, Body), erlang:element(3, Body));
                                                _ ->
                                                    ok({std@compiler@@Fn, erlang:element(2, Ps), erlang:element(2, Ret), erlang:element(2, Body)}, erlang:element(3, Body))
                                            end
                                    end
                            end
                    end
            end
    end.

fnParams(Ts, I, Holes) ->
    Out = [],
    Pos = I,
    Err = <<"">>,
    {Err@9, Pos@8, Out@5} = (fun __BpLoop({Err@1, Pos@1, Out@1}) ->
        case ((Err@1 =:= <<"">>) andalso (not isP(Ts, Pos@1, <<")">>))) of
            true ->
                T = tokAt(Ts, Pos@1),
                {Err@8, Pos@7, Out@4} = case ((erlang:element(2, T) =/= <<"name">>) orelse (not isP(Ts, '__bp_int'((Pos@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:482:46">>), <<":">>))) of
                    true ->
                        Err@2 = erlang:element(4, expected(Ts, Pos@1, <<"a typed parameter `name: Type`">>)),
                        {Err@2, Pos@1, Out@1};
                    _ ->
                        Ann = typeNode(Ts, '__bp_int'((Pos@1 + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:485:40">>), Holes),
                        {Err@7, Pos@6, Out@3} = case (erlang:element(4, Ann) =/= <<"">>) of
                            true ->
                                Err@3 = erlang:element(4, Ann),
                                Pos@2 = erlang:element(3, Ann),
                                {Err@3, Pos@2, Out@1};
                            _ ->
                                Out@2 = (Out@1 ++ [{std@compiler@@FnParam, erlang:element(3, T), erlang:element(2, Ann)}]),
                                Pos@3 = erlang:element(3, Ann),
                                {Pos@5, Err@6} = case isP(Ts, Pos@3, <<",">>) of
                                    true ->
                                        Pos@4 = '__bp_int'((Pos@3 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:493:31">>),
                                        {Pos@4, Err@1};
                                    _ ->
                                        Err@5 = case (not isP(Ts, Pos@3, <<")">>)) of
                                            true ->
                                                Err@4 = erlang:element(4, expected(Ts, Pos@3, <<"`,` or `)`">>)),
                                                Err@4;
                                            _ ->
                                                Err@1
                                        end,
                                        {Pos@3, Err@5}
                                end,
                                {Err@6, Pos@5, Out@2}
                        end,
                        {Err@7, Pos@6, Out@3}
                end,
                __BpLoop({Err@8, Pos@7, Out@4});
            _ -> {Err@1, Pos@1, Out@1}
        end
    end)({Err, Pos, Out}),
    case (Err@9 =/= <<"">>) of
        true ->
            {std@code@@Params, Out@5, Pos@8, Err@9};
        _ ->
            {std@code@@Params, Out@5, '__bp_int'((Pos@8 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:500:41">>), <<"">>}
    end.

% A function's statements after its `{`, up to and past its `}`: `return e;`

% a `Return`, any other an expression.

statements(Ts, I, Holes) ->
    Out = [],
    Pos = I,
    Err = <<"">>,
    {Err@6, Pos@8, Out@7} = (fun __BpLoop({Err@1, Pos@1, Out@1}) ->
        case ((Err@1 =:= <<"">>) andalso (not isP(Ts, Pos@1, <<"}">>))) of
            true ->
                {Err@5, Pos@7, Out@6} = case (erlang:element(2, tokAt(Ts, Pos@1)) =:= <<"eof">>) of
                    true ->
                        Err@2 = erlang:element(4, expected(Ts, Pos@1, <<"`}`">>)),
                        {Err@2, Pos@1, Out@1};
                    _ ->
                        Returned = isWord(Ts, Pos@1, <<"return">>),
                        V = expr(Ts, case Returned of
                            true ->
                                '__bp_int'((Pos@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:514:48">>);
                            false ->
                                Pos@1
                        end, Holes),
                        {Err@4, Pos@6, Out@5} = case (erlang:element(4, V) =/= <<"">>) of
                            true ->
                                Err@3 = erlang:element(4, V),
                                Pos@2 = erlang:element(3, V),
                                {Err@3, Pos@2, Out@1};
                            _ ->
                                Out@4 = case Returned of
                                    true ->
                                        Out@2 = (Out@1 ++ [{std@compiler@@Return, erlang:element(2, V)}]),
                                        Out@2;
                                    _ ->
                                        Out@3 = (Out@1 ++ [erlang:element(2, V)]),
                                        Out@3
                                end,
                                Pos@3 = erlang:element(3, V),
                                Pos@5 = case isP(Ts, Pos@3, <<";">>) of
                                    true ->
                                        Pos@4 = '__bp_int'((Pos@3 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:524:50">>),
                                        Pos@4;
                                    _ ->
                                        Pos@3
                                end,
                                {Err@1, Pos@5, Out@4}
                        end,
                        {Err@4, Pos@6, Out@5}
                end,
                __BpLoop({Err@5, Pos@7, Out@6});
            _ -> {Err@1, Pos@1, Out@1}
        end
    end)({Err, Pos, Out}),
    case (Err@6 =/= <<"">>) of
        true ->
            {std@code@@Ps, Out@7, Pos@8, Err@6};
        _ ->
            {std@code@@Ps, Out@7, '__bp_int'((Pos@8 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:529:36">>), <<"">>}
    end.

% ── The types (decision 753) ───────────────────────────────────────────────

% `A | B`, or one type.

typeNode(Ts, I, Holes) ->
    First = arrayType(Ts, I, Holes),
    case ((erlang:element(4, First) =/= <<"">>) orelse (not isP(Ts, erlang:element(3, First), <<"|">>))) of
        true ->
            First;
        _ ->
            Members = [erlang:element(2, First)],
            Pos = erlang:element(3, First),
            Err = <<"">>,
            {Err@4, Pos@5, Members@4} = (fun __BpLoop({Err@1, Pos@1, Members@1}) ->
                case ((Err@1 =:= <<"">>) andalso isP(Ts, Pos@1, <<"|">>)) of
                    true ->
                        M = arrayType(Ts, '__bp_int'((Pos@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:542:35">>), Holes),
                        {Err@3, Pos@4, Members@3} = case (erlang:element(4, M) =/= <<"">>) of
                            true ->
                                Err@2 = erlang:element(4, M),
                                Pos@2 = erlang:element(3, M),
                                {Err@2, Pos@2, Members@1};
                            _ ->
                                Members@2 = (Members@1 ++ [erlang:element(2, M)]),
                                Pos@3 = erlang:element(3, M),
                                {Err@1, Pos@3, Members@2}
                        end,
                        __BpLoop({Err@3, Pos@4, Members@3});
                    _ -> {Err@1, Pos@1, Members@1}
                end
            end)({Err, Pos, Members}),
            case (Err@4 =/= <<"">>) of
                true ->
                    bad(Err@4, Pos@5);
                _ ->
                    ok({std@compiler@@UnionType, Members@4}, Pos@5)
            end
    end.

% `T[]`, `T[][]`, or one type.

arrayType(Ts, I, Holes) ->
    Cur = baseType(Ts, I, Holes),
    Cur@3 = (fun __BpLoop(Cur@1) ->
        case (((erlang:element(4, Cur@1) =:= <<"">>) andalso isP(Ts, erlang:element(3, Cur@1), <<"[">>)) andalso isP(Ts, '__bp_int'((erlang:element(3, Cur@1) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:560:28">>), <<"]">>)) of
            true ->
                Cur@2 = ok({std@compiler@@ArrayType, erlang:element(2, Cur@1)}, '__bp_int'((erlang:element(3, Cur@1) + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:561:53">>)),
                __BpLoop(Cur@2);
            _ -> Cur@1
        end
    end)(Cur),
    Cur@3.

baseType(Ts, I, Holes) ->
    T = tokAt(Ts, I),
    case (erlang:element(2, T) =:= <<"hole">>) of
        true ->
            ok(case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Holes, erlang:element(4, T)) of
                undefined ->
                    {std@compiler@@Lit, 0};
                __bp_nullish ->
                    __bp_nullish
            end, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:568:67">>));
        _ ->
            case isP(Ts, I, <<"?">>) of
                true ->
                    Inner = arrayType(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:570:37">>), Holes),
                    case (erlang:element(4, Inner) =/= <<"">>) of
                        true ->
                            Inner;
                        _ ->
                            ok({std@compiler@@OptionalType, erlang:element(2, Inner)}, erlang:element(3, Inner))
                    end;
                _ ->
                    case (isP(Ts, I, <<"#">>) andalso isP(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:574:38">>), <<"(">>)) of
                        true ->
                            tupleType(Ts, '__bp_int'((I + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:575:32">>), Holes);
                        _ ->
                            case isWord(Ts, I, <<"fn">>) of
                                true ->
                                    case (not isP(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:577:24">>), <<"(">>)) of
                                        true ->
                                            expected(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:577:57">>), <<"`(` after `fn`">>);
                                        _ ->
                                            Ps = typeList(Ts, '__bp_int'((I + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:578:33">>), Holes, <<")">>),
                                            case (erlang:element(4, Ps) =/= <<"">>) of
                                                true ->
                                                    bad(erlang:element(4, Ps), erlang:element(3, Ps));
                                                _ ->
                                                    case (not isP(Ts, erlang:element(3, Ps), <<"->">>)) of
                                                        true ->
                                                            expected(Ts, erlang:element(3, Ps), <<"`->` and the return type">>);
                                                        _ ->
                                                            Ret = typeNode(Ts, '__bp_int'((erlang:element(3, Ps) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:582:39">>), Holes),
                                                            case (erlang:element(4, Ret) =/= <<"">>) of
                                                                true ->
                                                                    Ret;
                                                                _ ->
                                                                    ok({std@compiler@@FnType, erlang:element(2, Ps), erlang:element(2, Ret)}, erlang:element(3, Ret))
                                                            end
                                                    end
                                            end
                                    end;
                                _ ->
                                    case (erlang:element(2, T) =:= <<"name">>) of
                                        true ->
                                            case isP(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:587:23">>), <<"<">>) of
                                                true ->
                                                    Args = typeList(Ts, '__bp_int'((I + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:588:39">>), Holes, <<">">>),
                                                    case (erlang:element(4, Args) =/= <<"">>) of
                                                        true ->
                                                            bad(erlang:element(4, Args), erlang:element(3, Args));
                                                        _ ->
                                                            ok({std@compiler@@GenericType, erlang:element(3, T), erlang:element(2, Args)}, erlang:element(3, Args))
                                                    end;
                                                _ ->
                                                    ok({std@compiler@@NamedType, erlang:element(3, T)}, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:592:40">>))
                                            end;
                                        _ ->
                                            case isP(Ts, I, <<"(">>) of
                                                true ->
                                                    Inner@1 = typeNode(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:595:36">>), Holes),
                                                    case (erlang:element(4, Inner@1) =/= <<"">>) of
                                                        true ->
                                                            Inner@1;
                                                        _ ->
                                                            case (not isP(Ts, erlang:element(3, Inner@1), <<")">>)) of
                                                                true ->
                                                                    expected(Ts, erlang:element(3, Inner@1), <<"`)`">>);
                                                                _ ->
                                                                    ok(erlang:element(2, Inner@1), '__bp_int'((erlang:element(3, Inner@1) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:598:41">>))
                                                            end
                                                    end;
                                                _ ->
                                                    expected(Ts, I, <<"a type">>)
                                            end
                                    end
                            end
                    end
            end
    end.

% Types separated by `,` up to and past `close`.

typeList(Ts, I, Holes, Close) ->
    Out = [],
    Pos = I,
    Err = <<"">>,
    {Err@7, Pos@7, Out@4} = (fun __BpLoop({Err@1, Pos@1, Out@1}) ->
        case ((Err@1 =:= <<"">>) andalso (not isP(Ts, Pos@1, Close))) of
            true ->
                V = typeNode(Ts, Pos@1, Holes),
                {Err@6, Pos@6, Out@3} = case (erlang:element(4, V) =/= <<"">>) of
                    true ->
                        Err@2 = erlang:element(4, V),
                        Pos@2 = erlang:element(3, V),
                        {Err@2, Pos@2, Out@1};
                    _ ->
                        Out@2 = (Out@1 ++ [erlang:element(2, V)]),
                        Pos@3 = erlang:element(3, V),
                        {Pos@5, Err@5} = case isP(Ts, Pos@3, <<",">>) of
                            true ->
                                Pos@4 = '__bp_int'((Pos@3 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:617:27">>),
                                {Pos@4, Err@1};
                            _ ->
                                Err@4 = case (not isP(Ts, Pos@3, Close)) of
                                    true ->
                                        Err@3 = erlang:element(4, expected(Ts, Pos@3, <<"`,` or `", Close/binary, "`">>)),
                                        Err@3;
                                    _ ->
                                        Err@1
                                end,
                                {Pos@3, Err@4}
                        end,
                        {Err@5, Pos@5, Out@2}
                end,
                __BpLoop({Err@6, Pos@6, Out@3});
            _ -> {Err@1, Pos@1, Out@1}
        end
    end)({Err, Pos, Out}),
    case (Err@7 =/= <<"">>) of
        true ->
            {std@code@@Ps, Out@4, Pos@7, Err@7};
        _ ->
            {std@code@@Ps, Out@4, '__bp_int'((Pos@7 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:623:36">>), <<"">>}
    end.

% `#(A, B)` or `#(a: A, b: B)`, after its `#(`.

tupleType(Ts, I, Holes) ->
    Labelled = ((erlang:element(2, tokAt(Ts, I)) =:= <<"name">>) andalso isP(Ts, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:628:61">>), <<":">>)),
    Types = [],
    Labels = [],
    Pos = I,
    Err = <<"">>,
    {Err@9, Labels@5, Pos@10, Types@5} = (fun __BpLoop({Err@1, Labels@1, Pos@1, Types@1}) ->
        case ((Err@1 =:= <<"">>) andalso (not isP(Ts, Pos@1, <<")">>))) of
            true ->
                T = tokAt(Ts, Pos@1),
                {Err@8, Labels@4, Pos@9, Types@4} = case (Labelled andalso (((erlang:element(2, T) =/= <<"name">>) orelse (not isP(Ts, '__bp_int'((Pos@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:635:59">>), <<":">>))))) of
                    true ->
                        Err@2 = erlang:element(4, expected(Ts, Pos@1, <<"a labelled element `name: Type`">>)),
                        {Err@2, Labels@1, Pos@1, Types@1};
                    _ ->
                        {Labels@3, Pos@3} = case Labelled of
                            true ->
                                Labels@2 = (Labels@1 ++ [erlang:element(3, T)]),
                                Pos@2 = '__bp_int'((Pos@1 + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:640:27">>),
                                {Labels@2, Pos@2};
                            _ ->
                                {Labels@1, Pos@1}
                        end,
                        V = typeNode(Ts, Pos@3, Holes),
                        {Err@7, Pos@8, Types@3} = case (erlang:element(4, V) =/= <<"">>) of
                            true ->
                                Err@3 = erlang:element(4, V),
                                Pos@4 = erlang:element(3, V),
                                {Err@3, Pos@4, Types@1};
                            _ ->
                                Types@2 = (Types@1 ++ [erlang:element(2, V)]),
                                Pos@5 = erlang:element(3, V),
                                {Pos@7, Err@6} = case isP(Ts, Pos@5, <<",">>) of
                                    true ->
                                        Pos@6 = '__bp_int'((Pos@5 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:650:31">>),
                                        {Pos@6, Err@1};
                                    _ ->
                                        Err@5 = case (not isP(Ts, Pos@5, <<")">>)) of
                                            true ->
                                                Err@4 = erlang:element(4, expected(Ts, Pos@5, <<"`,` or `)`">>)),
                                                Err@4;
                                            _ ->
                                                Err@1
                                        end,
                                        {Pos@5, Err@5}
                                end,
                                {Err@6, Pos@7, Types@2}
                        end,
                        {Err@7, Labels@3, Pos@8, Types@3}
                end,
                __BpLoop({Err@8, Labels@4, Pos@9, Types@4});
            _ -> {Err@1, Labels@1, Pos@1, Types@1}
        end
    end)({Err, Labels, Pos, Types}),
    case (Err@9 =/= <<"">>) of
        true ->
            bad(Err@9, Pos@10);
        _ ->
            case Labelled of
                true ->
                    ok({std@compiler@@LabeledTupleType, Types@5, Labels@5}, '__bp_int'((Pos@10 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:658:71">>));
                _ ->
                    ok({std@compiler@@TupleType, Types@5}, '__bp_int'((Pos@10 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/code.bp:659:44">>))
            end
    end.

array_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            lists:sublist(Self, (Start) + 1, ((End) - (Start)));
        false ->
            lists:nthtail(Start, Self)
    end.

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

-compile({inline,['__bp_nz'/2]}).
'__bp_nz'(B, What) when B == 0 -> erlang:error({panic, What});
'__bp_nz'(B, _) -> B.

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

'__bp_priv__array_slice'(A0, A1, A2) -> array_slice(A0, A1, A2).
