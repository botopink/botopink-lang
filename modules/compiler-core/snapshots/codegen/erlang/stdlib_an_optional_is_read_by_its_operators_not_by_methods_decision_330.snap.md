----- SOURCE CODE -- main.bp
```botopink
type Person(name: string)
fn find(p: Person) -> ?Person { @todo(); }
fn greet(p: Person) -> string {
    return find(p)?.name ?? "Hello stranger";
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Person: name

find(P) ->
    erlang:error({todo, <<"not implemented">>}).

greet(P) ->
    case (fun(undefined) -> undefined; (_Opt0) -> erlang:element(2, _Opt0) end)(find(P)) of
        undefined ->
            <<"Hello stranger">>;
        __bp_nullish ->
            __bp_nullish
    end.
```

----- ERLANG -- test@main@@Person.erl
```erlang
-module(test@main@@Person).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Person", [{"name", erlang:element(2, V)}]}.
```

----- RUN LOG -----
```logs
```
