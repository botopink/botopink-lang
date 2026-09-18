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

main({Arg0}) ->
    try
        json:encode('__bp_reply'(conf(Arg0)))
    catch
        throw:{'__bp_template_fail', Message, Param, Span} ->
            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), param => Param, span => '__bp_json'(Span)});
        Class:Reason ->
            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
    end.

%% main/1 argument — an external term, not part of the module:
%% Arg0 = #{
%%     '__bp_capture' => <<"q">>,
%%     text => <<"yaml">>,
%%     parts => [
%%         #{
%%             kind => <<"Text">>,
%%             text => <<"yaml">>,
%%             span => #{start => 0, 'end' => 4, line => 1}
%%         }
%%     ],
%%     source => #{file => <<"">>, line => 7, col => 16},
%%     context => #{
%%         source => #{file => <<"">>, line => 7, col => 16},
%%         text => <<"yaml">>,
%%         multiline => false
%%     },
%%     bindings => [
%%         #{name => <<"conf">>, kind => 'Fn'},
%%         #{name => <<"cfg">>, kind => 'Val'},
%%         #{name => <<"main">>, kind => 'Fn'}
%%     ]
%% }
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

----- JAVASCRIPT -- main.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(Number.isInteger(v) ? v.toFixed(1) : String(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof v.tag === "string") ? ((v.__bp + ".") + v.tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], null, false, a))).join(", ")) + ")")));
    }
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

const cfg = [8004, true];

function main() {
    __bp_print((cfg[0] + 1));
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
