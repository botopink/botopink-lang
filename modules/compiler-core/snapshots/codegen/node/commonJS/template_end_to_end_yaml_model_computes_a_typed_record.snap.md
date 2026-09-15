----- SOURCE CODE -- main.bp
```botopink
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val t = q.text();
    return @expr(record { port: 8000 + t.length, debug: true });
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
    expr(#{port => '__bp_add'(8000, '__bp_len'(T, length)), debug => true}).

main() ->
    try
        json:encode('__bp_reply'(conf(#{'__bp_capture' => <<"q">>, text => <<"yaml">>, parts => [#{kind => <<"Text">>, text => <<"yaml">>, span => #{start => 0, 'end' => 4, line => 1}}], source => #{file => <<"">>, line => 5, col => 16}, context => #{source => #{file => <<"">>, line => 5, col => 16}, text => <<"yaml">>, multiline => false}, bindings => [#{name => <<"conf">>, kind => 'Fn'}, #{name => <<"cfg">>, kind => 'Val'}, #{name => <<"main">>, kind => 'Fn'}]})))
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
    "port": 8004,
    "debug": true
  },
  "kind": "value"
}
```

----- JAVASCRIPT -- main.js
```javascript
const cfg = ({ port: 8004, debug: true });

function main() {
    console.log((cfg.port + 1));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
8005
```
