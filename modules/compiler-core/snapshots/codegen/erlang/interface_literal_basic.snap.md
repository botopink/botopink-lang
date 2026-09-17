----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val DeclKind = record { Record: "Record", Fn: "Fn" };
    val decl = @Decl(kind: DeclKind.Record, name: "Service", fields: [], methods: [], returnType: "", annotations: []);
    @print(decl.name);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    DeclKind = #{'Record' => <<"Record">>, 'Fn' => <<"Fn">>},
    Decl = #{kind => maps:get('Record', DeclKind), name => <<"Service">>, fields => [], methods => [], returnType => <<"">>, annotations => []},
    '__bp_print'([maps:get(name, Decl)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
Service
```
