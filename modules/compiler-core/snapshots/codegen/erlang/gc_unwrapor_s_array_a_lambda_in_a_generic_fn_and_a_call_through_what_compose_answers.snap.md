----- SOURCE CODE -- std/functions.bp
```botopink
//// std/functions — combinators over function values (decision 738).
////
//// Plain functions of a std module, imported by path:
//// `import {functions.compose} from "std";`. A function's type is
//// `fn(A) -> B`; no `Function` contract names it. Pure botopink, no host
//// backing, so the module runs on every target.
////
//// No import (decision 106: a root module).

/// The argument, unchanged.
pub fn identity<A>(x: A) -> A {
    return x;
}

/// `f`, then `g`: `compose(f, g)(a)` is `g(f(a))`.
pub fn compose<A, B, C>(f: fn(a: A) -> B, g: fn(b: B) -> C) -> fn(A) -> C {
    return { a -> g(f(a)) };
}

/// `f` with its two arguments swapped: `flip(f)(b, a)` is `f(a, b)`.
pub fn flip<A, B, C>(f: fn(a: A, b: B) -> C) -> fn(B, A) -> C {
    return { b, a -> f(a, b) };
}

/// A function answering `x` whatever it is given. The argument is typed
/// `unknown` (decision 668: no parameter would bind a type for it), so one
/// binding takes any argument.
pub fn constant<A>(x: A) -> fn(unknown) -> A {
    return { ignored -> x };
}

test "functions.identity" {
    assert identity(42) == 42;
    assert identity("hi") == "hi";
    assert identity(true);
}

test "functions.compose runs left to right" {
    val double: fn(i32) -> i32 = { n -> n * 2 };
    val addOne: fn(i32) -> i32 = { n -> n + 1 };
    val f = compose(double, addOne);
    assert f(3) == 7;
    assert f(0) == 1;
}

test "functions.compose with a string transform" {
    val shout: fn(string) -> string = { s -> s + "!" };
    val greet: fn(string) -> string = { s -> "Hello, " + s };
    val greetAndShout = compose(greet, shout);
    assert greetAndShout("world") == "Hello, world!";
}

test "functions.flip reverses the argument order" {
    val sub: fn(i32, i32) -> i32 = { a, b -> a - b };
    val rsub = flip(sub);
    assert rsub(3, 10) == 7;
}

test "functions.constant ignores its argument" {
    val always42 = constant(42);
    assert always42("anything") == 42;
    assert always42(0) == 42;
}

```

----- ERLANG -- std/functions.erl
```erlang
-module(std@functions).
-export([identity/1, compose/2, flip/1, constant/1]).

%%% std/functions — combinators over function values (decision 738).

%%% 

%%% Plain functions of a std module, imported by path:

%%% `import {functions.compose} from "std";`. A function's type is

%%% `fn(A) -> B`; no `Function` contract names it. Pure botopink, no host

%%% backing, so the module runs on every target.

%%% 

%%% No import (decision 106: a root module).

%% The argument, unchanged.

identity(X) ->
    X.

%% `f`, then `g`: `compose(f, g)(a)` is `g(f(a))`.

compose(F, G) ->
    fun(A) ->
        G(F(A))
    end.

%% `f` with its two arguments swapped: `flip(f)(b, a)` is `f(a, b)`.

flip(F) ->
    fun(B, A) ->
        F(A, B)
    end.

%% A function answering `x` whatever it is given. The argument is typed

%% `unknown` (decision 668: no parameter would bind a type for it), so one

%% binding takes any argument.

constant(X) ->
    fun(Ignored) ->
        X
    end.





```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn parse(s: string) -> Result<array<#(string, string)>, string> {
    if (s == "") throw "empty";
    return [#(s, s.toUpper())];
}

fn pairsOf(r: Result<array<#(string, string)>, string>) -> string {
    val none: array<#(string, string)> = [];
    return r.unwrapOr(none).map({ p -> [p._0, "=>", p._1].join("") }).join("|");
}

pub fn main() -> void {
    print(pairsOf(parse("a")));
    print(pairsOf(parse("")).length);
    val double: fn(i32) -> i32 = { n -> n * 2 };
    val addOne: fn(i32) -> i32 = { n -> n + 1 };
    print(functions.compose(double, addOne)(3));
    val shout: fn(string) -> string = { s -> s + "!" };
    print(functions.compose(shout, shout)("hi"));
    val sub: fn(i32, i32) -> i32 = { a, b -> a - b };
    print(functions.flip(sub)(3, 10));
    print(functions.constant(42)("x"));
}

import {io.terminal.print} from "std";
import {functions} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__parse'/1, '__bp_priv__pairsOf'/1]).

parse(S) ->
    case (S =:= <<"">>) of
        true ->
            {error, <<"empty">>};
        _ ->
            {ok, [{S, string:uppercase(S)}]}
    end.

pairsOf(R) ->
    None = [],
    iolist_to_binary(lists:join(<<"|">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(P) ->
        iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [erlang:element(1, P), <<"=>">>, erlang:element(2, P)])))
    end, (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (None) end end)(R))))).

main() ->
    '__bp_print'([pairsOf(parse(<<"a">>))]),
    '__bp_print'([erlang:length(unicode:characters_to_list(pairsOf(parse(<<"">>))))]),
    Double = fun(N) ->
        '__bp_int'((N * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:14:43">>)
    end,
    AddOne = fun(N) ->
        '__bp_int'((N + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:15:43">>)
    end,
    '__bp_print'([(std@functions:compose(Double, AddOne))(3)]),
    Shout = fun(S) ->
        <<('__bp_text'(S))/binary, "!">>
    end,
    '__bp_print'([(std@functions:compose(Shout, Shout))(<<"hi">>)]),
    Sub = fun(A, B) ->
        '__bp_int'((A - B), -2147483648, 2147483647, <<"integer overflow: - on i32 at main.bp:19:48">>)
    end,
    '__bp_print'([(std@functions:flip(Sub))(3, 10)]),
    '__bp_print'([(std@functions:constant(42))(<<"x">>)]).

%% import functions

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

'__bp_priv__parse'(A0) -> parse(A0).

'__bp_priv__pairsOf'(A0) -> pairsOf(A0).
```

----- RUN LOG -----
```logs
a=>A
0
7
hi!!
7
42
```
