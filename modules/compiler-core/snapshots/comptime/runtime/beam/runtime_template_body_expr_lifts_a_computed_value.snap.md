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

main({Arg0}) ->
    try
        json:encode('__bp_reply'(six(Arg0)))
    catch
        throw:{'__bp_template_fail', Message, Param, Span} ->
            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), param => Param, span => '__bp_json'(Span)});
        Class:Reason ->
            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
    end.

%% main/1 argument — an external term, not part of the module:
%% Arg0 = #{
%%     '__bp_capture' => <<"t">>,
%%     text => <<"ignored">>,
%%     parts => [
%%         #{
%%             kind => <<"Text">>,
%%             text => <<"ignored">>,
%%             span => #{start => 0, 'end' => 7, line => 1}
%%         }
%%     ],
%%     source => #{file => <<"">>, line => 5, col => 13},
%%     context => #{
%%         source => #{file => <<"">>, line => 5, col => 13},
%%         text => <<"ignored">>,
%%         multiline => false
%%     },
%%     bindings => [#{name => <<"six">>, kind => 'Fn'}, #{name => <<"n">>, kind => 'Val'}]
%% }
```

----- COMPTIME REPLY -- template six
```json
{
  "kind": "value",
  "value": 6
}
```

