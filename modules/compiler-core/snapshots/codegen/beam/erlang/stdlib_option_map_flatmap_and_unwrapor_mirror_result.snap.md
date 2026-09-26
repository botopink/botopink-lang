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
    (fun(__BpO) -> case __BpO of undefined -> (<<"Hello stranger">>); __BpV0 -> __BpV0 end end)((fun(__BpO) -> case __BpO of undefined -> undefined; __BpV1 -> (fun(N) ->
        shout(N)
    end)(__BpV1) end end)((fun(__BpO) -> case __BpO of undefined -> undefined; __BpV2 -> (fun(N) ->
        <<"Hello ", ('__bp_text'(N))/binary>>
    end)(__BpV2) end end)(firstName(P)))).

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
