----- SOURCE CODE -- main.bp
```botopink
type Box<T>(value: T) {
    pub fn get(self: Self<T>) -> T {
        return self.value;
    }
}

type Maybe<T> {
    Some(value: T),
    None,
}

fn orZero(m: Maybe<i32>) -> i32 {
    return case m {
        Maybe.Some(value: v) -> v;
        Maybe.None -> 0;
    };
}

fn ident<T>(x: T) -> T {
    return x;
}

pub fn main() -> void {
    val b = Box(value: 41);
    print(b.value + 1);
    print(b.get());
    print(Box(value: "s"));
    print(Box(value: true));
    print(orZero(Maybe.Some(value: 7)), orZero(Maybe.None));
    print(Maybe.Some(value: "x"));
    print(ident(3) + 1);
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__orZero'/1, '__bp_priv__ident'/1]).

%% type Box: value

%% type Maybe
%%   Some(value)
%%   None

orZero(M) ->
    case M of
        {test@main@@Maybe__v__some, V} ->
            V;
        test@main@@Maybe__v__none ->
            0
    end.

ident(X) ->
    X.

main() ->
    B = {test@main@@Box, 41},
    '__bp_print'(['__bp_int'((erlang:element(2, B) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:25:19">>)]),
    '__bp_print'([test@main@@Box:get(B)]),
    '__bp_print'([{test@main@@Box, <<"s">>}]),
    '__bp_print'([{test@main@@Box, true}]),
    '__bp_print'([orZero({test@main@@Maybe__v__some, 7}), orZero(test@main@@Maybe__v__none)]),
    '__bp_print'([{test@main@@Maybe__v__some, <<"x">>}]),
    '__bp_print'(['__bp_int'((ident(3) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:31:20">>)]).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'__bp_priv__orZero'(A0) -> orZero(A0).

'__bp_priv__ident'(A0) -> ident(A0).
```

----- ERLANG -- test@main@@Box.erl
```erlang
-module(test@main@@Box).
-compile({no_auto_import,[get/1]}).
-export([get/1, '__bp_get'/2, '__bp_format'/1]).

get(Self) ->
    erlang:element(2, Self).

'__bp_get'(V, value) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Box", [{"value", erlang:element(2, V)}]}.
```

----- ERLANG -- test@main@@Maybe.erl
```erlang
-module(test@main@@Maybe).
-export(['__bp_format'/1]).

'__bp_format'({test@main@@Maybe__v__some, F0}) -> {variant, "Maybe.Some", [{"value", F0}]};
'__bp_format'(test@main@@Maybe__v__none) -> {variant, "Maybe.None", []}.
```

----- RUN LOG -----
```logs
42
41
Box(value: "s")
Box(value: true)
7 0
Maybe.Some(value: "x")
4
```
