----- SOURCE CODE -- main.bp
```botopink
pub type Button(
    label: string,
)
pub fn need(comptime t: @Expr<string>) -> @Expr<string> {
    val hit = t.lookup("Buttom");
    if (hit) { b ->
        return t.fail("should be missing");
    };
    return t.build("\"ok\"");
}
val r = need "x";
```

----- COMPTIME ERLANG -- template need
```erlang
need(T) ->
    Hit = lookup(T, <<"Buttom">>),
    case Hit of
        undefined ->
            build(T, <<"\"ok\"">>);
        B ->
            fail(T, <<"should be missing">>)
    end.

main() ->
    try
        json:encode('__bp_reply'(need(#{
            '__bp_capture' => <<"t">>,
            text => <<"x">>,
            parts => [
                #{
                    kind => <<"Text">>,
                    text => <<"x">>,
                    span => #{start => 0, 'end' => 1, line => 1}
                }
            ],
            source => #{file => <<"">>, line => 11, col => 14},
            context => #{
                source => #{file => <<"">>, line => 11, col => 14},
                text => <<"x">>,
                multiline => false
            },
            bindings => [
                #{name => <<"Button">>, kind => 'Record_'},
                #{name => <<"need">>, kind => 'Fn'},
                #{name => <<"r">>, kind => 'Val'}
            ]
        })))
    catch
        throw:{'__bp_template_fail', Message, Param, Span} ->
            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), param => Param, span => '__bp_json'(Span)});
        Class:Reason ->
            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
    end.
```

----- COMPTIME REPLY -- template need
```json
{
  "source": "\"ok\"",
  "kind": "code"
}
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
pub type Button(
    label: string,
)

val r = "ok";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Button",
      "fields": {
        "label": "string"
      }
    },
    {
      "ast": "fn_def",
      "name": "need",
      "is_pub": true,
      "params": [
        {
          "name": "t",
          "type": "Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "Expr<string>",
      "body": [
        {
          "source": "val hit = t.lookup(\"Buttom\");"
        },
        {
          "source": "if (hit) { b ->"
        },
        {
          "source": "return t.build(\"\\\"ok\\\"\");"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "r",
      "return_type": "string"
    }
  ]
}
```

