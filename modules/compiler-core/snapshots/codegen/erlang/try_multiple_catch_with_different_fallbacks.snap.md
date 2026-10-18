----- SOURCE CODE -- main.bp
```botopink
type UserError(msg: string)
fn fetchName() -> Result<string, UserError> {
    throw UserError(msg: "name missing");
}
fn fetchAge() -> Result<i32, UserError> {
    throw UserError(msg: "age missing");
}
fn loadUser() {
    val name = try fetchName() catch "anonymous";
    val age = try fetchAge() catch 0;
    print(name, age);
}
fn main() {
    loadUser();
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export(['__bp_priv__fetchName'/0, '__bp_priv__fetchAge'/0, '__bp_priv__loadUser'/0, '__bp_priv__main'/0]).

%% type UserError: msg

fetchName() ->
    {error, {test@main@@UserError, <<"name missing">>}}.

fetchAge() ->
    {error, {test@main@@UserError, <<"age missing">>}}.

loadUser() ->
    Name = case fetchName() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            <<"anonymous">>
    end,
    Age = case fetchAge() of
        {ok, TryV1} -> TryV1;
        {error, _TryE1} ->
            0
    end,
    '__bp_print'([Name, Age]).

main() ->
    loadUser().

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

'__bp_priv__fetchName'() -> fetchName().

'__bp_priv__fetchAge'() -> fetchAge().

'__bp_priv__loadUser'() -> loadUser().

'__bp_priv__main'() -> main().
```

----- ERLANG -- test@main@@UserError.erl
```erlang
-module(test@main@@UserError).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, msg) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "UserError", [{"msg", erlang:element(2, V)}]}.
```

----- RUN LOG -----
```logs
anonymous 0
```
