----- SOURCE CODE -- main.bp
```botopink
record Doc {
    title: string,

    fn print(self: Self) -> string {
        return "doc:" + self.title;
    }
}

fn main() {
    val d = Doc(title: "hi");
    @print(d.print());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record Doc: title

print(Self) ->
    <<"doc:", ('__bp_text'(maps:get(title, Self)))/binary>>.

main() ->
    D = #{title => <<"hi">>},
    '__bp_print'([print(D)]).

'__bp_text'(Value) when is_binary(Value) -> Value;
'__bp_text'(Value) -> iolist_to_binary(io_lib:format(<<"~p">>, [Value])).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
doc:hi
```
