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
-module(test@main).
-compile({no_auto_import,[node/0]}).
-export(['_botopink_init'/0, '__bp_priv__node'/0, '__bp_priv__box'/1, '__bp_priv__many'/0, '__bp_priv__one'/0, '__bp_priv__txt'/0]).

node() ->
    <<"n">>.

box(Children) ->
    <<"x">>.

many() ->
    case persistent_term:get({test@main, many}, '__bp_unset') of
        '__bp_unset' -> __BpV = box([node(), node()]), persistent_term:put({test@main, many}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

one() ->
    case persistent_term:get({test@main, one}, '__bp_unset') of
        '__bp_unset' -> __BpV = box(node()), persistent_term:put({test@main, one}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

txt() ->
    case persistent_term:get({test@main, txt}, '__bp_unset') of
        '__bp_unset' -> __BpV = box(<<"hi">>), persistent_term:put({test@main, txt}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'_botopink_init'() ->
    many(),
    one(),
    txt(),
    ok.

'__bp_priv__node'() -> node().

'__bp_priv__box'(A0) -> box(A0).

'__bp_priv__many'() -> many().

'__bp_priv__one'() -> one().

'__bp_priv__txt'() -> txt().
```

----- RUN LOG -----
```logs
```
