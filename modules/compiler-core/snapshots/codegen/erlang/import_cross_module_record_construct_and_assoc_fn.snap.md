----- SOURCE CODE -- http.bp
```botopink
pub record Response {
    body: string,
    fn ok(body: string) -> Response {
        return Response(body: body);
    }
}

pub record App {
    port: i32,
    path: string,
}
```

----- ERLANG -- http.erl
```erlang
-module(http).
-export([ok/1]).

%% record Response: body

ok(Body) ->
    #{body => Body}.

%% record App: port, path
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {Response, App} from "http";

fn main() {
    val r = Response.ok("hi");
    @print(r.body);
    val a = App(8080, "/");
    @print(a.port);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import Response, App

main() ->
    R = http:ok(<<"hi">>),
    '__bp_print'([maps:get(body, R)]),
    A = #{port => 8080, path => <<"/">>},
    '__bp_print'([maps:get(port, A)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
hi
8080
```
