----- SOURCE CODE -- main.bp
```botopink
enum Status { Ok, Fail }
#[@result]
fn check(s: Status) -> @Result<i32, string> {
    return case s {
        Ok -> 1;
        Fail -> throw "failed";
    };
}
fn main() {
    @print(check(Status.Ok).isOk());
    @print(check(Status.Fail).isOk());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% enum Status
%%   Ok
%%   Fail

check(S) ->
    {ok, case S of
        'Ok' ->
            1;
        'Fail' ->
            {error, <<"failed">>}
    end}.

main() ->
    '__bp_print'([(fun(R) -> case R of {ok, _} -> true; _ -> false end end)(check('Ok'))]),
    '__bp_print'([(fun(R) -> case R of {ok, _} -> true; _ -> false end end)(check('Fail'))]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
true
true
```
