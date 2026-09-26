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

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\05\00\00\00start")
  (data (i32.const 268) "\01\00\00\00v")
  (data (i32.const 276) "\01\00\00\00,")
  (data (i32.const 284) "\2d\00\00\00Service(port: prop(port), name: makestring())")
  (global $__heap_ptr (mut i32) (i32.const 336))
  (func $collect (param $xs i32) (result i32)
    (local $__mem0 i32)
    (local $out i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $x i32)
    (local $doubled i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
    local.set $out
    local.get $out
    i32.const 256
    call $__arr_push
    local.set $out
    local.get $xs
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $x
    local.get $x
    i32.const 2
    i32.mul
    local.set $doubled
    local.get $out
    i32.const 268
    local.get $doubled
    call $__i32_to_str
    call $__str_concat
    call $__arr_push
    local.set $out
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $out
    return
  )
  (func $main
    (local $__mem0 i32)
    call $wireService
    call $__print_str
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 16
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 3
    i32.store
    local.get $__mem0
    i32.const 1
    i32.store offset=4
    local.get $__mem0
    i32.const 2
    i32.store offset=8
    local.get $__mem0
    i32.const 3
    i32.store offset=12
    local.get $__mem0
    call $collect
    i32.const 276
    call $__arr_join_str
    call $__print_str
  )
  (func $wireService (export "wireService") (result i32)
    i32.const 284
    return
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   32..64 float fraction   64..128 i32 digits
  (func $__write_bytes (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__print_nl
    i32.const 8
    i32.const 10
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  ;; separator between the arguments of a multi-argument `@print`
  (func $__print_sp
    i32.const 8
    i32.const 32
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i32 (param $n i32)
    local.get $n
    call $__print_i32_raw
    call $__print_nl
  )
  (func $__print_i32_raw (param $n i32)
    (local $buf i32) (local $len i32) (local $neg i32) (local $d i32)
    (local $i i32) (local $j i32) (local $tmp i32)
    i32.const 64
    local.set $buf
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 1
        local.set $neg
        i32.const 0
        local.get $n
        i32.sub
        local.set $n
      )
    )
    (block $done
      (loop $digits
        local.get $n
        i32.const 10
        i32.rem_u
        i32.const 48
        i32.add
        local.set $d
        local.get $buf
        local.get $len
        i32.add
        local.get $d
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
        local.get $n
        i32.const 10
        i32.div_u
        local.set $n
        local.get $n
        i32.const 0
        i32.gt_u
        br_if $digits
      )
    )
    ;; reverse
    i32.const 0
    local.set $i
    local.get $len
    i32.const 1
    i32.sub
    local.set $j
    (block $rdone
      (loop $rev
        local.get $i
        local.get $j
        i32.ge_u
        br_if $rdone
        local.get $buf
        local.get $i
        i32.add
        i32.load8_u
        local.set $tmp
        local.get $buf
        local.get $i
        i32.add
        local.get $buf
        local.get $j
        i32.add
        i32.load8_u
        i32.store8
        local.get $buf
        local.get $j
        i32.add
        local.get $tmp
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        local.get $j
        i32.const 1
        i32.sub
        local.set $j
        br $rev
      )
    )
    ;; add neg sign + newline
    ;; shift the digits one byte right to make room for '-'
    ;; (dst = buf+1, NOT buf+len: the latter moved them `len`
    ;;  bytes and printed -12 as -21)
    local.get $neg
    (if
      (then
        local.get $buf
        i32.const 1
        i32.add
        local.get $buf
        local.get $len
        call $__memmove
        local.get $buf
        i32.const 45
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
      )
    )
    local.get $buf
    local.get $len
    call $__write_bytes
  )
  (func $__memmove (param $dst i32) (param $src i32) (param $len i32)
    (local $i i32)
    local.get $len
    i32.const 1
    i32.sub
    local.set $i
    (block $done
      (loop $loop
        local.get $i
        i32.const 0
        i32.lt_s
        br_if $done
        local.get $dst
        local.get $i
        i32.add
        local.get $src
        local.get $i
        i32.add
        i32.load8_u
        i32.store8
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        br $loop
      )
    )
  )
  (func $__print_str_raw (param $s i32)
    local.get $s
    i32.const 256
    i32.lt_u
    (if
      (then
        ;; a pointer below the data floor is not a string
        unreachable
      )
    )
    local.get $s
    i32.const 4
    i32.add
    local.get $s
    i32.load
    call $__write_bytes
  )
  (func $__print_str (param $s i32)
    local.get $s
    call $__print_str_raw
    call $__print_nl
  )
  (func $__str_concat (param $a i32) (param $b i32) (result i32)
    (local $base i32) (local $alen i32) (local $blen i32)
    local.get $a
    i32.load
    local.set $alen
    local.get $b
    i32.load
    local.set $blen
    global.get $__heap_ptr
    local.set $base
    ;; bump heap by 4 (length prefix) + alen + blen
    global.get $__heap_ptr
    i32.const 4
    local.get $alen
    i32.add
    local.get $blen
    i32.add
    i32.add
    global.set $__heap_ptr
    ;; store combined length prefix
    local.get $base
    local.get $alen
    local.get $blen
    i32.add
    i32.store
    ;; copy a's bytes: base+4 <- a+4
    local.get $base
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.add
    local.get $alen
    memory.copy
    ;; copy b's bytes: base+4+alen <- b+4
    local.get $base
    i32.const 4
    i32.add
    local.get $alen
    i32.add
    local.get $b
    i32.const 4
    i32.add
    local.get $blen
    memory.copy
    local.get $base
  )
  (func $__alloc (param $n i32) (result i32)
    (local $p i32)
    global.get $__heap_ptr
    local.set $p
    global.get $__heap_ptr
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    global.set $__heap_ptr
    local.get $p
  )
  (func $__i32_to_str (param $n i32) (result i32)
    (local $u i64) (local $pos i32) (local $len i32) (local $p i32) (local $neg i32)
    i32.const 160
    local.set $pos
    local.get $n
    i32.const 0
    i32.lt_s
    local.set $neg
    local.get $n
    i64.extend_i32_s
    local.set $u
    local.get $neg
    (if
      (then
        i64.const 0
        local.get $u
        i64.sub
        local.set $u
      )
    )
    (block $brk
      (loop $cont
        local.get $pos
        i32.const 1
        i32.sub
        local.set $pos
        local.get $pos
        local.get $u
        i64.const 10
        i64.rem_u
        i32.wrap_i64
        i32.const 48
        i32.add
        i32.store8
        local.get $u
        i64.const 10
        i64.div_u
        local.set $u
        local.get $u
        i64.eqz
        br_if $brk
        br $cont
      )
    )
    local.get $neg
    (if
      (then
        local.get $pos
        i32.const 1
        i32.sub
        local.set $pos
        local.get $pos
        i32.const 45
        i32.store8
      )
    )
    i32.const 160
    local.get $pos
    i32.sub
    local.set $len
    local.get $len
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $len
    i32.store
    local.get $p
    i32.const 4
    i32.add
    local.get $pos
    local.get $len
    memory.copy
    local.get $p
  )
  (func $__arr_new (param $n i32) (result i32)
    (local $p i32)
    local.get $n
    i32.const 1
    i32.add
    i32.const 4
    i32.mul
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
    local.get $p
  )
  (func $__arr_push (param $xs i32) (param $x i32) (result i32)
    (local $n i32) (local $p i32)
    local.get $xs
    i32.load
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $xs
    i32.const 4
    i32.add
    local.get $n
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
    i32.const 4
    i32.add
    local.get $n
    i32.const 4
    i32.mul
    i32.add
    local.get $x
    i32.store
    local.get $p
  )
  (func $__arr_join_str (param $xs i32) (param $sep i32) (result i32)
    (local $n i32) (local $i i32) (local $total i32) (local $p i32) (local $pos i32) (local $e i32)
    local.get $xs
    i32.load
    local.set $n
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $total
        local.get $xs
        i32.const 4
        i32.add
        local.get $i
        i32.const 4
        i32.mul
        i32.add
        i32.load
        i32.load
        i32.add
        local.set $total
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $n
    (if
      (then
        local.get $total
        local.get $sep
        i32.load
        local.get $n
        i32.const 1
        i32.sub
        i32.mul
        i32.add
        local.set $total
      )
    )
    local.get $total
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $total
    i32.store
    local.get $p
    i32.const 4
    i32.add
    local.set $pos
    i32.const 0
    local.set $i
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $i
        (if
          (then
            local.get $pos
            local.get $sep
            i32.const 4
            i32.add
            local.get $sep
            i32.load
            memory.copy
            local.get $pos
            local.get $sep
            i32.load
            i32.add
            local.set $pos
          )
        )
        local.get $xs
        i32.const 4
        i32.add
        local.get $i
        i32.const 4
        i32.mul
        i32.add
        i32.load
        local.set $e
        local.get $pos
        local.get $e
        i32.const 4
        i32.add
        local.get $e
        i32.load
        memory.copy
        local.get $pos
        local.get $e
        i32.load
        i32.add
        local.set $pos
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
  )
)
```

----- RUN LOG -----
```logs
Service(port: prop(port), name: makestring())
start,v2,v4,v6
```
