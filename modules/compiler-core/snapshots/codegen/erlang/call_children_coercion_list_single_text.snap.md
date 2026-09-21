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
-compile({no_auto_import,[node/0]}).
-export(['_botopink_init'/0]).

node() ->
    <<"n">>.

box(Children) ->
    <<"x">>.

many() ->
    case persistent_term:get({main, many}, '__bp_unset') of
        '__bp_unset' -> __BpV = box([node(), node()]), persistent_term:put({main, many}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

one() ->
    case persistent_term:get({main, one}, '__bp_unset') of
        '__bp_unset' -> __BpV = box(node()), persistent_term:put({main, one}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

txt() ->
    case persistent_term:get({main, txt}, '__bp_unset') of
        '__bp_unset' -> __BpV = box(<<"hi">>), persistent_term:put({main, txt}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'_botopink_init'() ->
    many(),
    one(),
    txt(),
    ok.
```

----- RUN LOG -----
```logs
```
