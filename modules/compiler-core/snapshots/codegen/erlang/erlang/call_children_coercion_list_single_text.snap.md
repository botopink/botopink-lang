----- SOURCE CODE -- main.bp
```botopink
fn node() -> string { return "n"; }
fn box(children: Children) -> string { return "x"; }
val many = box([node(), node()]);
val one = box(node());
val txt = box("hi");
```

----- ERLANG -- main.erl
```erlang
-module(main).

node() ->
    <<"n">>.

box(Children) ->
    <<"x">>.

many() ->
    box([node(), node()]).

one() ->
    box(node()).

txt() ->
    box(<<"hi">>).
```

----- RUN LOG -----
```logs
```
