----- SOURCE CODE -- main.bp
```botopink
type Counter(n: i32, label: string) {
    pub fn bump(self: Self) -> i32 {
        return self.n + 1;
    }
    pub fn name(self: Self) -> string {
        return self.label + "!";
    }
    pub fn scaled(self: Self, k: i32) -> i32 {
        return self.n * k;
    }
    pub fn twice(self: Self) -> Counter {
        return Counter(n: self.n * 2, label: self.label);
    }
}

pub fn main() {
    val c = Counter(n: 4, label: "ctr");
    print(c.bump());
    print(c.name());
    print(c.scaled(3));
    print(c.twice());
    print(c.twice().twice().n);
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0]).

%% type Counter: n, label

main() ->
    C = {test@main@@Counter, 4, <<"ctr">>},
    '__bp_print'([test@main@@Counter:bump(C)]),
    '__bp_print'([test@main@@Counter:name(C)]),
    '__bp_print'([test@main@@Counter:scaled(C, 3)]),
    '__bp_print'([test@main@@Counter:twice(C)]),
    '__bp_print'([erlang:element(2, test@main@@Counter:twice(test@main@@Counter:twice(C)))]).

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
```

----- ERLANG -- test@main@@Counter.erl
```erlang
-module(test@main@@Counter).
-export([bump/1, name/1, scaled/2, twice/1, '__bp_get'/2, '__bp_format'/1]).

bump(Self) ->
    '__bp_int'((erlang:element(2, Self) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:3:23">>).

name(Self) ->
    <<('__bp_text'(erlang:element(3, Self)))/binary, "!">>.

scaled(Self, K) ->
    '__bp_int'((erlang:element(2, Self) * K), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:9:23">>).

twice(Self) ->
    {test@main@@Counter, '__bp_int'((erlang:element(2, Self) * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:12:34">>), erlang:element(3, Self)}.

'__bp_get'(V, n) -> erlang:element(2, V);
'__bp_get'(V, label) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Counter", [{"n", erlang:element(2, V)}, {"label", erlang:element(3, V)}]}.

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
```

----- RUN LOG -----
```logs
5
ctr!
12
Counter(n: 8, label: "ctr")
16
```
