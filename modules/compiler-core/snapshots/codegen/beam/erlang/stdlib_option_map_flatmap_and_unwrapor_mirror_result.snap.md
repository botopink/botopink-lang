----- SOURCE CODE -- main.bp
```botopink
type Person(name: string)
fn firstName(p: Person) -> ?string { @todo(); }
fn shout(s: string) -> ?string { @todo(); }
fn greet(p: Person) -> string {
    return firstName(p)
        .map({ n -> "Hello " + n })
        .flatMap({ n -> shout(n) })
        .unwrapOr("Hello stranger");
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Person: name

firstName(P) ->
    erlang:error({todo, <<"not implemented">>}).

shout(S) ->
    erlang:error({todo, <<"not implemented">>}).

greet(P) ->
    (fun(O) -> case O of undefined -> (<<"Hello stranger">>); V -> V end end)((fun(O) -> case O of undefined -> undefined; V -> (fun(N) ->
        shout(N)
    end)(V) end end)((fun(O) -> case O of undefined -> undefined; V -> (fun(N) ->
        <<"Hello ", ('__bp_text'(N))/binary>>
    end)(V) end end)(firstName(P)))).

'__bp_text'(Value) when is_binary(Value) -> Value;
'__bp_text'(Value) -> iolist_to_binary(io_lib:format(<<"~p">>, [Value])).
```

----- ERLANG -- test@main@@Person.erl
```erlang
-module(test@main@@Person).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> element(2, V).

'__bp_format'(V) -> {record, "Person", [{"name", element(2, V)}]}.
```

----- RUN LOG -----
```logs
```
