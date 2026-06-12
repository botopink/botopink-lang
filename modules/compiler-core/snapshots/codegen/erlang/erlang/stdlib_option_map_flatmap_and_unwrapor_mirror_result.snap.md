----- SOURCE CODE -- main.bp
```botopink
record Person { name: string }
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
-module(main).

%% record Person: name

firstName(P) ->
    erlang:error({todo, "not implemented"}).

shout(S) ->
    erlang:error({todo, "not implemented"}).

greet(P) ->
    (fun(O) -> case O of undefined -> (<<"Hello stranger">>); V -> V end end)((fun(O) -> case O of undefined -> undefined; V -> (fun(N) ->
        shout(N)
    end)(V) end end)((fun(O) -> case O of undefined -> undefined; V -> (fun(N) ->
        (<<"Hello ">> + N)
    end)(V) end end)(firstName(P)))).
```

----- RUN LOG -----
```logs
```
