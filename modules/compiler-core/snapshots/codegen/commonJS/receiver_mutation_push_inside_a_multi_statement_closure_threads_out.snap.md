----- SOURCE CODE -- main.bp
```botopink
pub fn component(comptime decl: @Decl) {
    var args: Array<string> = [];
    decl.fields.forEach({ f ->
        var valKey = "";
        f.annotations.forEach({ a -> if (a.name == "value") { valKey = a.args.join(""); } });
        val expr = if (valKey != "") {
            "prop(" + valKey + ")";
        } else {
            "make" + f.typeName + "()";
        };
        args.push(f.name + ": " + expr);
    });
    @emit("pub fn wire" + decl.name + "() -> string { return \"" + decl.name + "(" + args.join(", ") + ")\"; }");
}

#[component]
record Service {
    #[value(port)]
    port: i32,
    name: string,
}

fn collect(xs: Array<i32>) -> Array<string> {
    var out: Array<string> = [];
    out.push("start");
    xs.forEach({ x ->
        val doubled = x * 2;
        out.push("v" + doubled.toString());
    });
    return out;
}

fn main() {
    @print(wireService());
    @print(collect([1, 2, 3]).join(","));
}
```

----- COMPTIME ERLANG -- decorator component
```erlang
component(Decl) ->
    Args = [],
    Args@3 = lists:foldl(fun(F, Args@1) ->
        ValKey = lists:foldl(fun(A, ValKey) ->
            case (maps:get(name, A) =:= <<"value">>) of
                true -> '__bp_prim_join'(maps:get(args, A), <<"">>);
                _ -> ValKey
            end
        end, <<"">>, maps:get(annotations, F)),
        Expr = case (ValKey =/= <<"">>) of
            true ->
                '__bp_add'('__bp_add'(<<"prop(">>, ValKey), <<")">>);
            false ->
                '__bp_add'('__bp_add'(<<"make">>, maps:get(typeName, F)), <<"()">>)
        end,
        Args@2 = '__bp_prim_push'(Args@1, '__bp_add'('__bp_add'(maps:get(name, F), <<": ">>), Expr)),
        Args@2
    end, Args, maps:get(fields, Decl)),
    emit('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'(<<"pub fn wire">>, maps:get(name, Decl)), <<"() -> string { return \"">>), maps:get(name, Decl)), <<"(">>), '__bp_prim_join'(Args@3, <<", ">>)), <<")\"; }">>)).

main() ->
    erlang:erase('__bp_emitted'),
    try
        component(#{
            kind => 'Record',
            name => <<"Service">>,
            fields => [
                #{
                    name => <<"port">>,
                    typeName => <<"i32">>,
                    annotations => [#{name => <<"value">>, args => [<<"port">>]}]
                },
                #{name => <<"name">>, typeName => <<"string">>, annotations => []}
            ],
            methods => [],
            returnType => <<"">>,
            annotations => [#{name => <<"component">>, args => []}]
        }),
        json:encode(#{kind => <<"ok">>, contributions => lists:reverse('__bp_emitted'())})
    catch
        throw:{'__bp_decorator_fail', Message, Span} ->
            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), span => Span});
        Class:Reason ->
            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
    end.
```

----- COMPTIME REPLY -- decorator component
```json
{
  "kind": "ok",
  "contributions": [
    "pub fn wireService() -> string { return \"Service(port: prop(port), name: makestring())\"; }"
  ]
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(",")) + (t ? ")" : "]"));
    }
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

class Service {
    constructor(port, name) {
        this.port = port;
        this.name = name;
    }
}

function collect(xs) {
    let out = [];
    out.push("start");
    xs.forEach((x) => {
    const doubled = (x * 2);
    return out.push(("v" + doubled.toString()));
});
    return out;
}

function main() {
    __bp_print(wireService());
    __bp_print(collect([1, 2, 3]).join(","));
}

function wireService() {
    return "Service(port: prop(port), name: makestring())";
}
exports.wireService = wireService;

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function component(decl: Decl): void;








export declare function wireService(): string;

```

----- RUN LOG -----
```logs
Service(port: prop(port), name: makestring())
start,v2,v4,v6
```
