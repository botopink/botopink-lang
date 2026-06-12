----- SOURCE CODE -- main.bp
```botopink
record UserError { msg: string }
#[@result]
fn fetchName() -> @Result<string, UserError> {
    throw UserError(msg: "name missing");
}
#[@result]
fn fetchAge() -> @Result<i32, UserError> {
    throw UserError(msg: "age missing");
}
fn loadUser() {
    val name = try fetchName() catch "anonymous";
    val age = try fetchAge() catch 0;
    @print(name, age);
}
fn main() {
    loadUser();
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record UserError: msg

fetchName() ->
    {error, #{msg => <<"name missing">>}}.

fetchAge() ->
    {error, #{msg => <<"age missing">>}}.

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
    io:format("~p~n", [Name, Age]).

main() ->
    loadUser().

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
