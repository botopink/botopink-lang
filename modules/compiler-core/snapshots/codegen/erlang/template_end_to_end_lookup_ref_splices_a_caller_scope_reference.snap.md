----- SOURCE CODE -- main.bp
```botopink
val greeting = "ola mundo";
pub fn refer(comptime q: @Expr<string>) -> @Expr<string> {
    val hit = q.lookup("greeting");
    if (hit) { b ->
        return b.ref();
    } else {
        return q.fail("greeting not found in caller scope");
    };
}
val s = refer "x";
fn main() {
    @print(s);
}
```

----- COMPTIME ERLANG -- template refer
```erlang
refer(Q) ->
    Hit = lookup(Q, <<"greeting">>),
    case Hit of
        undefined ->
            fail(Q, <<"greeting not found in caller scope">>);
        B ->
            ref(B)
    end.

main() ->
    try
        json:encode('__bp_reply'(refer(#{
            '__bp_capture' => <<"q">>,
            text => <<"x">>,
            parts => [
                #{
                    kind => <<"Text">>,
                    text => <<"x">>,
                    span => #{start => 0, 'end' => 1, line => 1}
                }
            ],
            source => #{file => <<"">>, line => 10, col => 15},
            context => #{
                source => #{file => <<"">>, line => 10, col => 15},
                text => <<"x">>,
                multiline => false
            },
            bindings => [
                #{name => <<"greeting">>, kind => 'Val'},
                #{name => <<"refer">>, kind => 'Fn'},
                #{name => <<"s">>, kind => 'Val'},
                #{name => <<"main">>, kind => 'Fn'}
            ]
        })))
    catch
        throw:{'__bp_template_fail', Message, Param, Span} ->
            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), param => Param, span => '__bp_json'(Span)});
        Class:Reason ->
            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
    end.
```

----- COMPTIME REPLY -- template refer
```json
{
  "source": "greeting",
  "kind": "code"
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

greeting() ->
    <<"ola mundo">>.

s() ->
    greeting().

main() ->
    '__bp_print'([s()]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
ola mundo
```
