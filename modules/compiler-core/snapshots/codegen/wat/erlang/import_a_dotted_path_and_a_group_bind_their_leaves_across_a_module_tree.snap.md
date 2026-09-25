----- SOURCE CODE -- shapes/circle.bp
```botopink
pub fn name() -> string {
    return "circle";
}

pub fn label() -> string {
    return "shapes/circle";
}
```

----- ERLANG -- shapes/circle.erl
```erlang
-module(test@shapes@circle).
-export([name/0, label/0]).

name() ->
    <<"circle">>.

label() ->
    <<"shapes/circle">>.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- shapes/helpers.bp
```botopink
pub fn seven() -> i32 {
    return 7;
}

pub fn label() -> string {
    return "shapes/helpers";
}
```

----- ERLANG -- shapes/helpers.erl
```erlang
-module(test@shapes@helpers).
-export([seven/0, label/0]).

seven() ->
    7.

label() ->
    <<"shapes/helpers">>.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {shapes.circle.name as circleName, shapes: {helpers: {seven, label}, circle: {label as circleLabel}}};

fn main() {
    @print(circleName());
    @print(seven());
    @print(label());
    @print(circleLabel());
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% import circleName, seven, label, circleLabel

main() ->
    '__bp_print'([test@shapes@circle:name()]),
    '__bp_print'([test@shapes@helpers:seven()]),
    '__bp_print'([test@shapes@helpers:label()]),
    '__bp_print'([test@shapes@circle:label()]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) when is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(atom_to_list(A), "__v__") of [P, _] -> list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
circle
7
shapes/helpers
shapes/circle
```
