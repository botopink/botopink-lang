----- SOURCE CODE -- main.bp
```botopink
pub fn describe(comptime decl: @Decl) {
    val names = decl.fields.map({ f -> f.name });
    val upper = names.map({ n -> n.toUpper() }).join("_");
    val hidden = if (names.contains("secret")) { "hidden"; } else { "open"; };
    val short = decl.name.slice(0, 3);
    val size = if (decl.name.length() == 4) { "four"; } else { "other"; };
    @emit("pub fn describe" + decl.name + "() -> string { return \"" + upper + ":" + hidden + ":" + short + ":" + size + "\"; }");
}

#[describe]
record User { name: string, secret: string, age: i32 }

fn main() {
    @print(describeUser());
}
```

----- COMPTIME ERLANG -- decorator describe
```erlang
describe(Decl) ->
    Names = '__bp_prim_map'(maps:get(fields, Decl), fun(F) ->
        maps:get(name, F)
    end),
    Upper = '__bp_prim_join'('__bp_prim_map'(Names, fun(N) ->
        '__bp_prim_toUpper'(N)
    end), <<"_">>),
    Hidden = case '__bp_prim_contains'(Names, <<"secret">>) of
        true ->
            <<"hidden">>;
        false ->
            <<"open">>
    end,
    Short = '__bp_prim_slice'(maps:get(name, Decl), 0, 3),
    Size = case ('__bp_prim_length'(maps:get(name, Decl)) =:= 4) of
        true ->
            <<"four">>;
        false ->
            <<"other">>
    end,
    emit('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'(<<"pub fn describe">>, maps:get(name, Decl)), <<"() -> string { return \"">>), Upper), <<":">>), Hidden), <<":">>), Short), <<":">>), Size), <<"\"; }">>)).

main() ->
    erlang:erase('__bp_emitted'),
    try
        describe(#{
            kind => 'Record',
            name => <<"User">>,
            fields => [
                #{name => <<"name">>, typeName => <<"string">>, annotations => []},
                #{name => <<"secret">>, typeName => <<"string">>, annotations => []},
                #{name => <<"age">>, typeName => <<"i32">>, annotations => []}
            ],
            methods => [],
            returnType => <<"">>,
            annotations => [#{name => <<"describe">>, args => []}]
        }),
        json:encode(#{kind => <<"ok">>, contributions => lists:reverse('__bp_emitted'())})
    catch
        throw:{'__bp_decorator_fail', Message, Span} ->
            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), span => Span});
        Class:Reason ->
            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
    end.
```

----- COMPTIME REPLY -- decorator describe
```json
{
  "kind": "ok",
  "contributions": [
    "pub fn describeUser() -> string { return \"NAME_SECRET_AGE:hidden:Use:four\"; }"
  ]
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).
-export([describeUser/0]).

%% interface String

%% interface Array

array_range(Start, Stop) ->
    case (Start >= Stop) of
        true ->
            [];
        false ->
            Head = Start,
            [Head] ++ (array_range((Start + 1), Stop))
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Head = Value,
            [Head] ++ (array_repeat(Value, (Times - 1)))
    end.

%% record User: name, secret, age

main() ->
    '__bp_print'([describeUser()]).

describeUser() ->
    <<"NAME_SECRET_AGE:hidden:Use:four">>.

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
NAME_SECRET_AGE:hidden:Use:four
```
