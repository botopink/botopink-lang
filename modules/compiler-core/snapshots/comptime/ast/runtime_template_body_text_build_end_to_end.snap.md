----- SOURCE CODE -- main.bp
```botopink
pub fn shout(comptime q: @Expr<string>) -> @Expr<string> {
    val t = q.text();
    return q.build("\"" + t + "!\"");
}
val s = shout "hey";
```

----- COMPTIME ERLANG -- template shout
```erlang
shout(Q) ->
    T = text(Q),
    build(Q, '__bp_add'('__bp_add'(<<"\"">>, T), <<"!\"">>)).

main() ->
    try
        json:encode('__bp_reply'(shout(#{
            '__bp_capture' => <<"q">>,
            text => <<"hey">>,
            parts => [
                #{
                    kind => <<"Text">>,
                    text => <<"hey">>,
                    span => #{start => 0, 'end' => 3, line => 1}
                }
            ],
            source => #{file => <<"">>, line => 5, col => 15},
            context => #{
                source => #{file => <<"">>, line => 5, col => 15},
                text => <<"hey">>,
                multiline => false
            },
            bindings => [#{name => <<"shout">>, kind => 'Fn'}, #{name => <<"s">>, kind => 'Val'}]
        })))
    catch
        throw:{'__bp_template_fail', Message, Param, Span} ->
            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), param => Param, span => '__bp_json'(Span)});
        Class:Reason ->
            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
    end.
```

----- COMPTIME REPLY -- template shout
```json
{
  "source": "\"hey!\"",
  "kind": "code"
}
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val s = "hey!";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "shout",
      "is_pub": true,
      "params": [
        {
          "name": "q",
          "type": "?",
          "is_comptime": true
        }
      ],
      "return_type": "?",
      "body": [
        {
          "source": "val t = q.text();"
        },
        {
          "source": "return q.build(\"\\\"\" + t + \"!\\\"\");"
        }
      ]
    },
    {
      "ast": "val",
      "indent": "s",
      "return_type": "string"
    }
  ]
}
```

