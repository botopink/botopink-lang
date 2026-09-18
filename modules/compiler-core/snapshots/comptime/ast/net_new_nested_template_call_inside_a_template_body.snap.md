----- SOURCE CODE -- main.bp
```botopink
pub fn inner(comptime q: @Expr<string>) -> @Expr<string> {
    return q;
}
pub fn outer(comptime q: @Expr<string>) -> @Expr<string> {
    return q.build("inner(\"deep\")");
}
val s = outer "x";
```

----- COMPTIME ERLANG -- template outer
```erlang
outer(Q) ->
    build(Q, <<"inner(\"deep\")">>).

main() ->
    try
        json:encode('__bp_reply'(outer(#{
            '__bp_capture' => <<"q">>,
            text => <<"x">>,
            parts => [
                #{
                    kind => <<"Text">>,
                    text => <<"x">>,
                    span => #{start => 0, 'end' => 1, line => 1}
                }
            ],
            source => #{file => <<"">>, line => 7, col => 15},
            context => #{
                source => #{file => <<"">>, line => 7, col => 15},
                text => <<"x">>,
                multiline => false
            },
            bindings => [
                #{name => <<"inner">>, kind => 'Fn'},
                #{name => <<"outer">>, kind => 'Fn'},
                #{name => <<"s">>, kind => 'Val'}
            ]
        })))
    catch
        throw:{'__bp_template_fail', Message, Param, Span} ->
            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), param => Param, span => '__bp_json'(Span)});
        Class:Reason ->
            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
    end.
```

----- COMPTIME REPLY -- template outer
```json
{
  "source": "inner(\"deep\")",
  "kind": "code"
}
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val s = inner();
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "inner",
      "is_pub": true,
      "params": [
        {
          "name": "q",
          "type": "Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "Expr<string>",
      "body": [
        {
          "source": "return q;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "outer",
      "is_pub": true,
      "params": [
        {
          "name": "q",
          "type": "Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "Expr<string>",
      "body": [
        {
          "source": "return q.build(\"inner(\\\"deep\\\")\");"
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

