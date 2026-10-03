----- SOURCE CODE -- http.bp
```botopink
pub type Response(
    body: string) {
    fn ok(body: string) -> Response {
        return Response(body: body);
    }
}

pub type App(
    port: i32,
    path: string,
)
```

----- ERLANG -- http.erl
```erlang
-module(test@http).

%% type Response: body

%% type App: port, path
```

----- ERLANG -- test@http@@Response.erl
```erlang
-module(test@http@@Response).
-export([ok/1, '__bp_get'/2, '__bp_format'/1]).

ok(Body) ->
    {test@http@@Response, Body}.

'__bp_get'(V, body) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Response", [{"body", erlang:element(2, V)}]}.
```

----- ERLANG -- test@http@@App.erl
```erlang
-module(test@http@@App).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, port) -> erlang:element(2, V);
'__bp_get'(V, path) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "App", [{"port", erlang:element(2, V)}, {"path", erlang:element(3, V)}]}.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {http.Response, http.App};

fn main() {
    val r = Response.ok("hi");
    @print(r.body);
    val a = App(8080, "/");
    @print(a.port);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% import Response, App

main() ->
    R = test@http@@Response:ok(<<"hi">>),
    '__bp_print'([erlang:element(2, R)]),
    A = {test@http@@App, 8080, <<"/">>},
    '__bp_print'([erlang:element(2, A)]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
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

----- RUN LOG -----
```logs
hi
8080
```
