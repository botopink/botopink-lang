----- SOURCE CODE -- main.bp
```botopink
pub fn six(comptime t: @Expr<string>) -> @Expr<i32> {
    val n = 2 + 4;
    return @expr(n);
}
val n = six "ignored";
```

----- COMPTIME ERLANG -- template six
```erlang
six(T) ->
    N = '__bp_add'(2, 4),
    expr(N).

main() ->
    try
        json:encode('__bp_reply'(six(#{
            '__bp_capture' => <<"t">>,
            text => <<"ignored">>,
            parts => [
                #{
                    kind => <<"Text">>,
                    text => <<"ignored">>,
                    span => #{start => 0, 'end' => 7, line => 1}
                }
            ],
            source => #{file => <<"">>, line => 5, col => 13},
            context => #{
                source => #{file => <<"">>, line => 5, col => 13},
                text => <<"ignored">>,
                multiline => false
            },
            bindings => [#{name => <<"six">>, kind => 'Fn'}, #{name => <<"n">>, kind => 'Val'}]
        })))
    catch
        throw:{'__bp_template_fail', Message, Param, Span} ->
            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), param => Param, span => '__bp_json'(Span)});
        Class:Reason ->
            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
    end.
```

----- COMPTIME REPLY -- template six
```json
{
  "value": 6,
  "kind": "value"
}
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val n = 6;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "six",
      "is_pub": true,
      "params": [
        {
          "name": "t",
          "type": "Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "Expr<i32>",
      "body": [
        {
          "source": "val n = 2 + 4;"
        },
        {
          "source": "return @expr(n);"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "n",
      "return_type": "i32"
    }
  ]
}
```

