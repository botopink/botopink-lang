----- SOURCE CODE -- main.bp
```botopink
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val t = q.text();
    val port = 8000 + t.length;
    val debug = true;
    return @expr(#(port, debug));
}
val cfg = conf "yaml";
fn main() {
    @print(cfg.port + 1);
}
```

----- COMPTIME ERLANG -- template conf
```erlang
conf(Q) ->
    T = text(Q),
    Port = '__bp_add'(8000, '__bp_len'(T, length)),
    Debug = true,
    expr({Port, Debug}).

main() ->
    try
        json:encode('__bp_reply'(conf(#{
            '__bp_capture' => <<"q">>,
            text => <<"yaml">>,
            parts => [
                #{
                    kind => <<"Text">>,
                    text => <<"yaml">>,
                    span => #{start => 0, 'end' => 4, line => 1}
                }
            ],
            source => #{file => <<"">>, line => 7, col => 16},
            context => #{
                source => #{file => <<"">>, line => 7, col => 16},
                text => <<"yaml">>,
                multiline => false
            },
            bindings => [
                #{name => <<"conf">>, kind => 'Fn'},
                #{name => <<"cfg">>, kind => 'Val'},
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

----- COMPTIME REPLY -- template conf
```json
{
  "value": {
    "$tuple": [
      8004,
      true
    ]
  },
  "kind": "value"
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

cfg() ->
    {8004, true}.

main() ->
    '__bp_print'([(element(1, cfg()) + 1)]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(",", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> io_lib:format("~p", [V]);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(",", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
8005
```
