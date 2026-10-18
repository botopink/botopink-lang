----- SOURCE CODE -- main.bp
```botopink
fn describe(x: unknown) -> string {
    return case x {
        i32 { n ->
            "number " + n.toString()
        }
        string { s ->
            "text " + s
        }
        _ {
            "other"
        }
    };
}

fn show(x: unknown) -> string {
    if (x is i32) return "i32";
    if (x is f64) return "f64";
    if (x is string) return "string";
    if (x is bool) return "bool";
    return "other";
}

pub fn main() {
    print(describe(3));
    print(describe("a"));
    print(describe(true));
    print(show(1), show(2.5), show("s"), show(false));
    val two: unknown = 2.0;
    print(two == 2, two == 3);
    val t: unknown = "hi";
    print(t == "hi", t);
    val b: unknown = true;
    print(b);
    print(300 is i8, 100 is i8, 2 is f64);
    val xs = [1, "a", true];
    print(xs);
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__describe'/1, '__bp_priv__show'/1]).

describe(X) ->
    case X of
        I32 when erlang:is_number(I32), (I32 == erlang:trunc(I32)), (I32 >= -2147483648), (I32 =< 2147483647) ->
            N = erlang:trunc(I32),
            <<"number ", ('__bp_text'(erlang:integer_to_binary(N)))/binary>>;
        S = String when erlang:is_binary(String) ->
            <<"text ", ('__bp_text'(S))/binary>>;
        _ ->
            <<"other">>
    end.

show(X) ->
    case (((erlang:is_number(X) andalso (X == erlang:trunc(X))) andalso (X >= -2147483648)) andalso (X =< 2147483647)) of
        true ->
            X@1 = erlang:trunc(X),
            <<"i32">>;
        _ ->
            case erlang:is_number(X) of
                true ->
                    X@2 = erlang:float(X),
                    <<"f64">>;
                _ ->
                    case erlang:is_binary(X) of
                        true ->
                            <<"string">>;
                        _ ->
                            case erlang:is_boolean(X) of
                                true ->
                                    <<"bool">>;
                                _ ->
                                    <<"other">>
                            end
                    end
            end
    end.

main() ->
    '__bp_print'([describe(3)]),
    '__bp_print'([describe(<<"a">>)]),
    '__bp_print'([describe(true)]),
    '__bp_print'([show(1), show(2.5), show(<<"s">>), show(false)]),
    Two = 2.0,
    '__bp_print'([(Two == 2), (Two == 3)]),
    T = <<"hi">>,
    '__bp_print'([(T == <<"hi">>), T]),
    B = true,
    '__bp_print'([B]),
    '__bp_print'([(fun(_Is0) -> (((erlang:is_number(_Is0) andalso (_Is0 == erlang:trunc(_Is0))) andalso (_Is0 >= -128)) andalso (_Is0 =< 127)) end)(300), (fun(_Is1) -> (((erlang:is_number(_Is1) andalso (_Is1 == erlang:trunc(_Is1))) andalso (_Is1 >= -128)) andalso (_Is1 =< 127)) end)(100), (fun(_Is2) -> erlang:is_number(_Is2) end)(2)]),
    Xs = [1, <<"a">>, true],
    '__bp_print'([Xs]).

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
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__describe'(A0) -> describe(A0).

'__bp_priv__show'(A0) -> show(A0).
```

----- RUN LOG -----
```logs
number 3
text a
other
i32 f64 string bool
true false
true hi
true
false true true
[1, "a", true]
```
