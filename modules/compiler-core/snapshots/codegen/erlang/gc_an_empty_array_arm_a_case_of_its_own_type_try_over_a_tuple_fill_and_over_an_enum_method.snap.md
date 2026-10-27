----- SOURCE CODE -- main.bp
```botopink
type Val {
    Num(n: i32),
    Text(s: string),

    fn str(self: Self) -> string {
        return case self {
            Text(s: t) -> t;
            _ -> "";
        };
    }
}

fn find(kind: i32) -> ?Val {
    if (kind == 1) return Val.Text(s: "a");
    if (kind == 2) return Val.Num(n: 40);
    return null;
}

fn contains(xs: string[], x: string) -> Result<void, string> {
    if (xs.indexOf(x) < 0) throw "missing";
    return;
}

fn pair(s: string) -> Result<#(string, string), string> {
    if (s == "") throw "empty";
    return #(s, s.toUpper());
}

fn label(s: string, loud: bool) -> string {
    val mark = case loud {
        true -> 1;
        false -> 0;
    };
    val parts = if (s == "") [] else [s, s];
    return parts.join("-") + mark.toString();
}

fn verdict(r: Result<void, string>) -> string {
    return case r {
        Ok(_) -> "ok";
        Error(e) -> e;
    };
}

fn both(s: string) -> Result<string, string> {
    val p = try pair(s);
    return p._0 + p._1;
}

fn text(r: Result<string, string>) -> string {
    return case r {
        Ok(v) -> v;
        Error(e) -> e;
    };
}

pub fn main() -> void {
    print(label("ab", true));
    print(label("", false));
    print("abc".contains("b"));
    print(verdict(contains(["a"], "b")));
    print(text(both("a")));
    print(text(both("")));
    print([1, 2, 3].fill("z"));
    print(find(1)?.str() ?? "none");
    print(find(3)?.str() ?? "none");
    print(Val.Num(n: 2).str().length);
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__find'/1, '__bp_priv__contains'/2, '__bp_priv__pair'/1, '__bp_priv__label'/2, '__bp_priv__verdict'/1, '__bp_priv__both'/1, '__bp_priv__text'/1, '__bp_priv__array_fill'/2]).

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

%% type Val
%%   Num(n)
%%   Text(s)

find(Kind) ->
    case (Kind =:= 1) of
        true ->
            {test@main@@Val__v__text, <<"a">>};
        _ ->
            case (Kind =:= 2) of
                true ->
                    {test@main@@Val__v__num, 40};
                _ ->
                    undefined
            end
    end.

contains(Xs, X) ->
    case ((fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(Xs, X) < 0) of
        true ->
            {error, <<"missing">>};
        _ ->
            {ok, undefined}
    end.

pair(S) ->
    case (S =:= <<"">>) of
        true ->
            {error, <<"empty">>};
        _ ->
            {ok, {S, string:uppercase(S)}}
    end.

label(S, Loud) ->
    Mark = case Loud of
        __bp_case_bool_0 when (__bp_case_bool_0 =:= true) ->
            1;
        __bp_case_bool_0@1 when (__bp_case_bool_0@1 =:= false) ->
            0
    end,
    Parts = case (S =:= <<"">>) of
        true ->
            [];
        false ->
            [S, S]
    end,
    '__bp_add'(iolist_to_binary(lists:join(<<"-">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Parts))), erlang:integer_to_binary(Mark)).

verdict(R) ->
    case R of
        {ok, _} ->
            <<"ok">>;
        {error, E} ->
            E
    end.

both(S) ->
    case pair(S) of
        {ok, P} ->
            {ok, '__bp_add'(erlang:element(1, P), erlang:element(2, P))};
        {error, _TryE0} -> {error, _TryE0}
    end.

text(R) ->
    case R of
        {ok, V} ->
            V;
        {error, E} ->
            E
    end.

main() ->
    '__bp_print'([label(<<"ab">>, true)]),
    '__bp_print'([label(<<"">>, false)]),
    '__bp_print'([(string:find(<<"abc">>, <<"b">>) =/= nomatch)]),
    '__bp_print'([verdict(contains([<<"a">>], <<"b">>))]),
    '__bp_print'([text(both(<<"a">>))]),
    '__bp_print'([text(both(<<"">>))]),
    '__bp_print'([array_fill([1, 2, 3], <<"z">>)]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain0) -> test@main@@Val:str(Bp__chain0) end)(find(1)) of
        undefined ->
            <<"none">>;
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain1) -> test@main@@Val:str(Bp__chain1) end)(find(3)) of
        undefined ->
            <<"none">>;
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([erlang:length(unicode:characters_to_list(test@main@@Val:str({test@main@@Val__v__num, 2})))]).

array_fill(Self, Value) ->
    array_repeat(Value, erlang:length(Self)).

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

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
'__bp_show'(V, _) when erlang:is_function(V) -> ["fn/", erlang:integer_to_list(erlang:element(2, erlang:fun_info(V, arity)))];
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

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__find'(A0) -> find(A0).

'__bp_priv__contains'(A0, A1) -> contains(A0, A1).

'__bp_priv__pair'(A0) -> pair(A0).

'__bp_priv__label'(A0, A1) -> label(A0, A1).

'__bp_priv__verdict'(A0) -> verdict(A0).

'__bp_priv__both'(A0) -> both(A0).

'__bp_priv__text'(A0) -> text(A0).

'__bp_priv__array_fill'(A0, A1) -> array_fill(A0, A1).
```

----- ERLANG -- test@main@@Val.erl
```erlang
-module(test@main@@Val).
-export([str/1, '__bp_format'/1]).

str(Self) ->
    case Self of
        {test@main@@Val__v__text, T} ->
            T;
        _ ->
            <<"">>
    end.

'__bp_format'({test@main@@Val__v__num, F0}) -> {variant, "Val.Num", [{"n", F0}]};
'__bp_format'({test@main@@Val__v__text, F0}) -> {variant, "Val.Text", [{"s", F0}]}.
```

----- RUN LOG -----
```logs
ab-ab1
0
true
missing
aA
empty
["z", "z", "z"]
a
none
0
```
