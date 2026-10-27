----- SOURCE CODE -- main.bp
```botopink
import {io.terminal.print} from "std";

type Shape { Circle(r: i32), Square(side: i32) }

type Person(name: string, age: i32)

fn parse(s: string) -> Result<i32, string> {
    if (s == "") throw "empty input";
    return s.length;
}

fn radius(s: Shape) -> i32 {
    val assert Circle(r) = s catch Shape.Circle(r: 0 - 1);
    return r;
}

fn describe(p: Person) -> string {
    val assert Person(n, a) = p;
    return n + "/" + a.toString();
}

fn size(s: string) -> i32 {
    val assert Ok(n) = parse(s);
    return n;
}

fn reason(s: string) -> string {
    val assert Error(message) = parse(s);
    return message;
}

fn older(p: Person) -> i32 {
    val assert Person(n, a) = p catch Person(name: "none", age: 0);
    return a + n.length;
}

pub fn main() -> void {
    print(radius(Shape.Circle(r: 3)));
    print(radius(Shape.Square(side: 2)));
    print(describe(Person(name: "ana", age: 30)));
    print(size("four"));
    print(reason(""));
    print(older(Person(name: "bo", age: 41)));
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-compile({no_auto_import,[size/1]}).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__parse'/1, '__bp_priv__radius'/1, '__bp_priv__describe'/1, '__bp_priv__size'/1, '__bp_priv__reason'/1, '__bp_priv__older'/1]).

%% type Shape
%%   Circle(r)
%%   Square(side)

%% type Person: name, age

parse(S) ->
    case (S =:= <<"">>) of
        true ->
            {error, <<"empty input">>};
        _ ->
            {ok, erlang:length(unicode:characters_to_list(S))}
    end.

radius(S) ->
    BpAssert13_9 = S,
    {test@main@@Shape__v__circle, R} = case BpAssert13_9 of {test@main@@Shape__v__circle, _} -> BpAssert13_9; _ -> {test@main@@Shape__v__circle, '__bp_int'((0 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at main.bp:13:54">>)} end,
    R.

describe(P) ->
    BpAssert18_9 = P,
    {test@main@@Person, N, A} = case BpAssert18_9 of {test@main@@Person, _, _} -> BpAssert18_9; _ -> erlang:error({panic, <<"assert pattern did not match">>}) end,
    <<('__bp_text'(N))/binary, "/", ('__bp_text'(erlang:integer_to_binary(A)))/binary>>.

size(S) ->
    BpAssert23_9 = parse(S),
    {ok, N} = case BpAssert23_9 of {ok, _} -> BpAssert23_9; _ -> erlang:error({panic, <<"assert pattern did not match">>}) end,
    N.

reason(S) ->
    BpAssert28_9 = parse(S),
    {error, Message} = case BpAssert28_9 of {error, _} -> BpAssert28_9; _ -> erlang:error({panic, <<"assert pattern did not match">>}) end,
    Message.

older(P) ->
    BpAssert33_9 = P,
    {test@main@@Person, N, A} = case BpAssert33_9 of {test@main@@Person, _, _} -> BpAssert33_9; _ -> {test@main@@Person, <<"none">>, 0} end,
    '__bp_int'((A + erlang:length(unicode:characters_to_list(N))), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:34:14">>).

main() ->
    '__bp_print'([radius({test@main@@Shape__v__circle, 3})]),
    '__bp_print'([radius({test@main@@Shape__v__square, 2})]),
    '__bp_print'([describe({test@main@@Person, <<"ana">>, 30})]),
    '__bp_print'([size(<<"four">>)]),
    '__bp_print'([reason(<<"">>)]),
    '__bp_print'([older({test@main@@Person, <<"bo">>, 41})]).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'__bp_priv__parse'(A0) -> parse(A0).

'__bp_priv__radius'(A0) -> radius(A0).

'__bp_priv__describe'(A0) -> describe(A0).

'__bp_priv__size'(A0) -> size(A0).

'__bp_priv__reason'(A0) -> reason(A0).

'__bp_priv__older'(A0) -> older(A0).
```

----- ERLANG -- test@main@@Shape.erl
```erlang
-module(test@main@@Shape).
-export(['__bp_format'/1]).

'__bp_format'({test@main@@Shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"r", F0}]};
'__bp_format'({test@main@@Shape__v__square, F0}) -> {variant, "Shape.Square", [{"side", F0}]}.
```

----- ERLANG -- test@main@@Person.erl
```erlang
-module(test@main@@Person).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, age) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Person", [{"name", erlang:element(2, V)}, {"age", erlang:element(3, V)}]}.
```

----- RUN LOG -----
```logs
3
-1
ana/30
4
empty input
43
```
