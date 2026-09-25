----- SOURCE CODE -- main.bp
```botopink
pub fn html(comptime q: @Expr<string>) -> @Expr<string> {
    var acc = "\"\"";
    for (q.parts()) { p ->
        if (p.kind == "Text") {
            acc = acc + " + \"" + p.text + "\"";
        };
        if (p.kind == "Interp") {
            acc = acc + " + " + p.code;
        };
    };
    return q.build(acc);
}
val name = "world";
val page = html """<p>${name}</p>""";
```

----- COMPTIME ERLANG -- template html
```erlang
html(Q) ->
    Acc = <<"\"\"">>,
    Acc@6 = lists:foldl(fun(P, Acc@1) ->
        Acc@3 = case (maps:get(kind, P) =:= <<"Text">>) of
            true ->
                Acc@2 = '__bp_add'('__bp_add'('__bp_add'(Acc@1, <<" + \"">>), maps:get(text, P)), <<"\"">>),
                Acc@2;
            _ ->
                Acc@1
        end,
        Acc@5 = case (maps:get(kind, P) =:= <<"Interp">>) of
            true ->
                Acc@4 = '__bp_add'('__bp_add'(Acc@3, <<" + ">>), maps:get(code, P)),
                Acc@4;
            _ ->
                Acc@3
        end,
        Acc@5
    end, Acc, parts(Q)),
    build(Q, Acc@6).

main({Arg0}) ->
    try
        json:encode('__bp_reply'(html(Arg0)))
    catch
        throw:{'__bp_template_fail', Message, Param, Span} ->
            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), param => Param, span => '__bp_json'(Span)});
        Class:Reason ->
            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
    end.

%% main/1 argument — an external term, not part of the module:
%% Arg0 = #{
%%     '__bp_capture' => <<"q">>,
%%     text => <<"<p>__bp_hole_q_0</p>">>,
%%     parts => [
%%         #{
%%             kind => <<"Text">>,
%%             text => <<"<p>">>,
%%             span => #{start => 0, 'end' => 3, line => 1}
%%         },
%%         #{
%%             kind => <<"Interp">>,
%%             code => <<"__bp_hole_q_0">>,
%%             span => #{start => 3, 'end' => 16, line => 1}
%%         },
%%         #{
%%             kind => <<"Text">>,
%%             text => <<"</p>">>,
%%             span => #{start => 16, 'end' => 20, line => 1}
%%         }
%%     ],
%%     source => #{file => <<"">>, line => 14, col => 17},
%%     context => #{
%%         source => #{file => <<"">>, line => 14, col => 17},
%%         text => <<"<p>__bp_hole_q_0</p>">>,
%%         multiline => true
%%     },
%%     bindings => [
%%         #{name => <<"html">>, kind => 'Fn'},
%%         #{name => <<"name">>, kind => 'Val'},
%%         #{name => <<"page">>, kind => 'Val'}
%%     ]
%% }
```

----- COMPTIME REPLY -- template html
```json
{
  "kind": "code",
  "source": "\"\" + \"<p>\" + __bp_hole_q_0 + \"</p>\""
}
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val name = "world";

val page = "" + "<p>" + name + "</p>";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "html",
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
          "source": "var acc = \"\\\"\\\"\";"
        },
        {
          "source": "for (q.parts()) { p ->"
        },
        {
          "source": "return q.build(acc);"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "name",
      "return_type": "string"
    },
    {
      "ast": "val",
      "ident": "page",
      "return_type": "string"
    }
  ]
}
```

