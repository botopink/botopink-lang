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

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {wireService, 0}]}.
{attributes, []}.
{labels, 18}.

{function, collect, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, collect}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"start">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, wireService, 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, wireService}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {literal, <<"Service(port: prop(port), name: makestring())">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 9}.
    {call_only, 0, {f, 5}}.

{function, main, 1, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 5}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 11}.
    {call_only, 0, {f, 9}}.

{function, '-collect/1-fun-0-', 1, 13}.
  {label, 12}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-collect/1-fun-0-'}, 1}.
  {label, 13}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, out}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"v">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 3}, {x, 0}}.
    %% unresolved method call: toString/1
    {gc_bif, '+', {f, 0}, 3, [{x, 2}, {x, 0}], {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 15}.
  {label, 14}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '-bp_stringify-'}, 1}.
  {label, 15}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 16}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 16}.
    {test, is_integer, {f, 17}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 17}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 0}.
```

----- RUN LOG -----
```logs
```
