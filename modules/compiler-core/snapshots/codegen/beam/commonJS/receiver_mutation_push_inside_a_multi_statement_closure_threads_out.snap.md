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
type Service(
    #[value(port)]
    port: i32,
    name: string,
)

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

----- COMPTIME BEAM ASSEMBLY -- decorator component
```erlang
{module, decorator_module}.
{exports, [{component, 1}, {main, 1}]}.
{attributes, []}.
{labels, 62}.

{function, '--component/1-fun-0--fun-1-', 2, 18}.
  {label, 17}.
    {func_info, {atom, decorator_module}, {atom, '--component/1-fun-0--fun-1-'}, 2}.
  {label, 18}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {atom, name}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, <<"value">>}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 22}, [{x, 0}, {atom, true}]}.
    {move, {atom, args}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, <<"">>}, {x, 1}}.
    {call_last, 2, {f, 4}, 4}.
  {label, 22}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '-component/1-fun-0-', 2, 14}.
  {label, 13}.
    {func_info, {atom, decorator_module}, {atom, '-component/1-fun-0-'}, 2}.
  {label, 14}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 18}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {atom, annotations}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {literal, <<"">>}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 25}}.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, <<"">>}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 27}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"prop(">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {literal, <<")">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 26}}.
  {label, 27}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 28}, [{x, 0}, {atom, false}]}.
    {move, {atom, typeName}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"make">>}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {literal, <<"()">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 26}}.
  {label, 28}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 26}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 30}}.
  {label, 30}.
    {move, {atom, name}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {literal, <<": ">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 6}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 2}}.
    {jump, {f, 32}}.
  {label, 32}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, component, 1, 2}.
  {label, 1}.
    {func_info, {atom, decorator_module}, {atom, component}, 1}.
  {label, 2}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {y, 0}}.
    {jump, {f, 12}}.
  {label, 12}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 14}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {atom, fields}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 34}}.
  {label, 34}.
    {move, {atom, name}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"pub fn wire">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, <<"() -> string { return \"">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {atom, name}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, <<"(">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, <<", ">>}, {x, 1}}.
    {call, 2, {f, 4}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, <<")\"; }">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, bp_comptime_decorator, emit, 1}, 5}.

{function, '-__bp_prim_join/2-fun-2-', 1, 39}.
  {label, 38}.
    {func_info, {atom, decorator_module}, {atom, '-__bp_prim_join/2-fun-2-'}, 1}.
  {label, 39}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 43}, [{x, 0}]}.
    {jump, {f, 44}}.
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 43}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 45}, [{x, 0}]}.
    {jump, {f, 46}}.
  {label, 46}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 2}.
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 47}, [{x, 0}]}.
    {jump, {f, 48}}.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 47}.
    {jump, {f, 50}}.
  {label, 50}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, [126, 112]}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 2}.

{function, '__bp_prim_join', 2, 4}.
  {label, 3}.
    {func_info, {atom, decorator_module}, {atom, '__bp_prim_join'}, 2}.
  {label, 4}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 36}, [{x, 0}]}.
    {jump, {f, 37}}.
  {label, 37}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 39}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 3}.
  {label, 36}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"join">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, '__bp_prim_push', 2, 6}.
  {label, 5}.
    {func_info, {atom, decorator_module}, {atom, '__bp_prim_push'}, 2}.
  {label, 6}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 53}, [{x, 0}]}.
    {jump, {f, 54}}.
  {label, 54}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 53}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_unsupported_method}, {literal, <<"push">>}, {integer, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 3}.

{function, main, 1, 8}.
  {label, 7}.
    {func_info, {atom, decorator_module}, {atom, main}, 1}.
  {label, 8}.
    {allocate, 16, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 57}, [{x, 0}]}.
    {test, test_arity, {f, 57}, [{x, 0}, 1]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {move, {atom, '__bp_emitted'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 7}}.
    {'try', {y, 15}, {f, 58}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 2}}.
    {move, {x, 0}, {y, 8}}.
    {call_ext, 0, {extfunc, bp_comptime_decorator, '__bp_emitted', 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"ok">>}, {atom, contributions}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {try_end, {y, 15}}.
    {jump, {f, 59}}.
  {label, 58}.
    {try_case, {y, 15}}.
    {move, {x, 0}, {y, 8}}.
    {move, {x, 1}, {y, 9}}.
    {move, {x, 2}, {y, 10}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 61}, [{x, 0}, {atom, throw}]}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tuple, {f, 61}, [{x, 0}]}.
    {test, test_arity, {f, 61}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 11}}.
    {get_tuple_element, {x, 0}, 1, {y, 12}}.
    {get_tuple_element, {x, 0}, 2, {y, 13}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 61}, [{x, 0}, {atom, '__bp_decorator_fail'}]}.
    {move, {y, 12}, {y, 1}}.
    {move, {y, 13}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_decorator, '__bp_text', 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"fail">>}, {atom, message}, {y, 14}, {atom, span}, {y, 2}]}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {y, 7}}.
    {jump, {f, 60}}.
  {label, 61}.
    {move, {y, 8}, {y, 3}}.
    {move, {y, 9}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_decorator, '__bp_text', 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"error">>}, {atom, message}, {y, 11}]}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 7}}.
    {jump, {f, 60}}.
  {label, 60}.
  {label, 59}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 16}.
    return.
  {label, 57}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 16}.
    {jump, {f, 7}}.

%% main/1 argument — an external term, not part of the module:
%% Arg0 = #{
%%     kind => 'Type',
%%     name => <<"Service">>,
%%     fields => [
%%         #{
%%             name => <<"port">>,
%%             typeName => <<"i32">>,
%%             annotations => [#{name => <<"value">>, args => [<<"port">>]}]
%%         },
%%         #{name => <<"name">>, typeName => <<"string">>, annotations => []}
%%     ],
%%     variants => [],
%%     methods => [],
%%     returnType => <<"">>,
%%     annotations => [#{name => <<"component">>, args => []}]
%% }
```

----- COMPTIME REPLY -- decorator component
```json
{
  "contributions": [
    "pub fn wireService() -> string { return \"Service(port: prop(port), name: makestring())\"; }"
  ],
  "kind": "ok"
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
    if ((v === undefined)) return "null";
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
Service.prototype.__bp = "Service";

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








export declare function wireService(): string;

```

----- RUN LOG -----
```logs
Service(port: prop(port), name: makestring())
start,v2,v4,v6
```
