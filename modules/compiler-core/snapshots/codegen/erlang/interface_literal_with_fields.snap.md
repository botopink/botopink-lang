----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val DeclKind = record { Record: "Record", Fn: "Fn" };
    val decl = @Decl(kind: DeclKind.Record, name: "Service", fields: [record { name: "x", typeName: "i32", annotations: [] }], methods: [], returnType: "", annotations: []);
    @print(decl.fields.length);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    DeclKind = #{'Record' => <<"Record">>, 'Fn' => <<"Fn">>},
    Decl = #{kind => maps:get('Record', DeclKind), name => <<"Service">>, fields => [#{name => <<"x">>, typeName => <<"i32">>, annotations => []}], methods => [], returnType => <<"">>, annotations => []},
    io:format("~p~n", [length(maps:get(fields, Decl))]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
1
```
