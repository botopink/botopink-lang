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

----- COMPTIME WAT -- decorator component
```wat
(func $component/1 (param $a0 i32) (result i32)
  (local $V_Decl i32) (local $t1 i32) (local $V_Args i32) (local $t2 i32) (local $t3 i32) (local $V_Args@3 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Decl
  call $rt_nil
  local.set $t1
  (block $L4
  (block $L3
  local.get $t1
  local.set $V_Args
  br $L4
  )
  local.get $t1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t1
  drop
  call $rt_nil
  local.set $t2
  global.get $__tbase
  i32.const 0
  i32.add
  i32.const 2
  local.get $t2
  call $rt_make_fun
  local.get $V_Args
  global.get $__lit
  i32.const 216
  i32.add
  i32.const 6
  call $rt_atom
  local.get $V_Decl
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $rt_lists_foldl
  call $rt_pending
  br_if $raise
  local.set $t3
  (block $L6
  (block $L5
  local.get $t3
  local.set $V_Args@3
  br $L6
  )
  local.get $t3
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t3
  drop
  global.get $__lit
  i32.const 224
  i32.add
  i32.const 11
  call $rt_bin
  global.get $__lit
  i32.const 112
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_Decl
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 240
  i32.add
  i32.const 23
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 112
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_Decl
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 264
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $V_Args@3
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 2
  call $rt_bin
  call $__bp_prim_join/2
  call $rt_pending
  br_if $raise
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 280
  i32.add
  i32.const 5
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  call $bp_comptime_decorator:emit/1
  call $rt_pending
  br_if $raise
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

(func $fun1:component/1 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_F i32) (local $V_Args@1 i32) (local $t1 i32) (local $t2 i32) (local $V_ValKey i32) (local $t3 i32) (local $t4 i32) (local $V_Expr i32) (local $t5 i32) (local $V_Args@2 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_F
  local.get $a1
  local.set $V_Args@1
  call $rt_nil
  local.set $t1
  global.get $__tbase
  i32.const 1
  i32.add
  i32.const 2
  local.get $t1
  call $rt_make_fun
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 0
  call $rt_bin
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 11
  call $rt_atom
  local.get $V_F
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $rt_lists_foldl
  call $rt_pending
  br_if $raise
  local.set $t2
  (block $L4
  (block $L3
  local.get $t2
  local.set $V_ValKey
  br $L4
  )
  local.get $t2
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t2
  drop
  local.get $V_ValKey
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 0
  call $rt_bin
  call $rt_eqx
  i32.eqz
  call $rt_bool
  local.set $t3
  (block $L5 (result i32)
  (block $L6
  local.get $t3
  global.get $__lit
  i32.const 128
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 5
  call $rt_bin
  local.get $V_ValKey
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 168
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  br $L5
  )
  (block $L7
  local.get $t3
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L7
  global.get $__lit
  i32.const 184
  i32.add
  i32.const 4
  call $rt_bin
  global.get $__lit
  i32.const 192
  i32.add
  i32.const 8
  call $rt_atom
  local.get $V_F
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 200
  i32.add
  i32.const 2
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  br $L5
  )
  local.get $t3
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $t4
  (block $L9
  (block $L8
  local.get $t4
  local.set $V_Expr
  br $L9
  )
  local.get $t4
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t4
  drop
  local.get $V_Args@1
  global.get $__lit
  i32.const 112
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_F
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 208
  i32.add
  i32.const 2
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $V_Expr
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  call $__bp_prim_push/2
  call $rt_pending
  br_if $raise
  local.set $t5
  (block $L11
  (block $L10
  local.get $t5
  local.set $V_Args@2
  br $L11
  )
  local.get $t5
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t5
  drop
  local.get $V_Args@2
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

(func $fun2:component/1 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_A i32) (local $V_ValKey i32) (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_A
  local.get $a1
  local.set $V_ValKey
  global.get $__lit
  i32.const 112
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_A
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 5
  call $rt_bin
  call $rt_eqx
  call $rt_bool
  local.set $t1
  (block $L3 (result i32)
  (block $L4
  local.get $t1
  global.get $__lit
  i32.const 128
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_A
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 0
  call $rt_bin
  call $__bp_prim_join/2
  call $rt_pending
  br_if $raise
  br $L3
  )
  (block $L5
  local.get $V_ValKey
  br $L3
  )
  local.get $t1
  call $rt_case_clause
  drop
  br $raise
  )
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

(func $__bp_prim_join/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $V_Arg0 i32) (local $t1 i32) (local $t2 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $V_Arg0
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $V_Arg0
  call $rt_nil
  local.set $t1
  global.get $__tbase
  i32.const 2
  i32.add
  i32.const 1
  local.get $t1
  call $rt_make_fun
  local.get $V_Recv
  call $rt_lists_map
  call $rt_pending
  br_if $raise
  call $rt_lists_join
  call $rt_pending
  br_if $raise
  call $rt_erlang_iolist_to_binary
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $t2
  local.get $t2
  i32.const 0
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t2
  i32.const 1
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 4
  call $rt_bin
  call $rt_tset
  drop
  local.get $t2
  i32.const 2
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $t2
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $t2
  call $rt_error
  call $rt_pending
  br_if $raise
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

(func $fun3:__bp_prim_join/2 (param $self i32) (param $a0 i32) (result i32)
  (local $V___E i32) (local $t1 i32) (local $t2 i32) (local $t3 i32) (local $t4 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V___E
  (block $L3 (result i32)
  (block $L4
  (block $L5
  (block $L6
  (block $L7
  local.get $V___E
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L7
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L6
  br $L5
  )
  call $rt_clear
  )
  br $L4
  )
  local.get $V___E
  br $L3
  )
  (block $L8
  (block $L9
  (block $L10
  (block $L11
  local.get $V___E
  call $rt_erlang_is_integer
  call $rt_pending
  br_if $L11
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L10
  br $L9
  )
  call $rt_clear
  )
  br $L8
  )
  local.get $V___E
  call $rt_erlang_integer_to_binary
  call $rt_pending
  br_if $raise
  br $L3
  )
  (block $L12
  (block $L13
  (block $L14
  (block $L15
  local.get $V___E
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L15
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L14
  br $L13
  )
  call $rt_clear
  )
  br $L12
  )
  local.get $V___E
  br $L3
  )
  (block $L16
  (block $L17
  (block $L18
  (block $L19
  global.get $__lit
  i32.const 128
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L18
  br $L17
  )
  call $rt_clear
  )
  br $L16
  )
  call $rt_nil
  local.set $t1
  i64.const 112
  call $rt_int
  local.get $t1
  call $rt_cons
  local.set $t2
  i64.const 126
  call $rt_int
  local.get $t2
  call $rt_cons
  local.get $V___E
  local.set $t3
  call $rt_nil
  local.set $t4
  local.get $t3
  local.get $t4
  call $rt_cons
  call $rt_io_lib_format
  call $rt_pending
  br_if $raise
  call $rt_erlang_iolist_to_binary
  call $rt_pending
  br_if $raise
  br $L3
  )
  call $rt_if_clause
  drop
  br $raise
  )
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

(func $__bp_prim_push/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $V_Arg0 i32) (local $t1 i32) (local $t2 i32) (local $t3 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $V_Arg0
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $V_Recv
  local.get $V_Arg0
  local.set $t1
  call $rt_nil
  local.set $t2
  local.get $t1
  local.get $t2
  call $rt_cons
  call $rt_append
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $t3
  local.get $t3
  i32.const 0
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t3
  i32.const 1
  global.get $__lit
  i32.const 344
  i32.add
  i32.const 4
  call $rt_bin
  call $rt_tset
  drop
  local.get $t3
  i32.const 2
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $t3
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $t3
  call $rt_error
  call $rt_pending
  br_if $raise
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

;; main/1 argument — an external term, not part of the module:
;; Arg0 = #{
;;     kind => 'Type',
;;     name => <<"Service">>,
;;     fields => [
;;         #{
;;             name => <<"port">>,
;;             typeName => <<"i32">>,
;;             annotations => [#{name => <<"value">>, args => [<<"port">>]}]
;;         },
;;         #{name => <<"name">>, typeName => <<"string">>, annotations => []}
;;     ],
;;     variants => [],
;;     methods => [],
;;     returnType => <<"">>,
;;     annotations => [#{name => <<"component">>, args => []}]
;; }
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

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {wireService, 0}]}.
{attributes, []}.
{labels, 46}.

{function, collect, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, collect}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"start">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {call, 0, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 19}}.
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
    {call, 1, {f, 3}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 45}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, wireService, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, wireService}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {literal, <<"Service(port: prop(port), name: makestring())">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 9}.
    {call_only, 0, {f, 5}}.

{function, main, 1, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 11}.
    {call_only, 0, {f, 9}}.

{function, '-bp_stringify-', 1, 15}.
  {label, 14}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-bp_stringify-'}, 1}.
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

{function, '-collect/1-fun-0-', 2, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-collect/1-fun-0-'}, 2}.
  {label, 13}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"v">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '__bp_print', 1, 19}.
  {label, 18}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 19}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 23}.
  {label, 22}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 23}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 21}}.

{function, '-bp_show_elem-', 1, 25}.
  {label, 24}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 25}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 21}}.

{function, '__bp_show', 2, 21}.
  {label, 20}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 21}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 33}, [{x, 0}]}.
    {test, is_eq, {f, 32}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 32}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 33}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 34}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 25}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 34}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 36}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 35}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 35}, [{x, 0}]}.
    {test, is_ne_exact, {f, 35}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 35}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 35}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 37}}.
  {label, 35}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 25}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 38}, [{x, 0}]}.
    {test, is_ne_exact, {f, 38}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 38}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 39}, [{x, 0}, {atom, undefined}]}.
  {label, 37}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 27}, 2}.
  {label, 38}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 39}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 27}.
  {label, 26}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 27}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 40}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 40}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 40}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 41}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 29}, 3}.
  {label, 41}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 29}.
  {label, 28}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 29}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 42}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 42}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 43}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 31}.
  {label, 30}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 31}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 21}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_join-', 2, 45}.
  {label, 44}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_join-'}, 2}.
  {label, 45}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.
```

----- BEAM ASSEMBLY -- test@main@@Service.S
```erlang
{module, test@main@@Service}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "test@main@@Service.erl", 1}]}.
    {func_info, {atom, test@main@@Service}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, port}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, name}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 7}.
  {label, 6}.
    {line, [{location, "test@main@@Service.erl", 1}]}.
    {func_info, {atom, test@main@@Service}, {atom, '__bp_format'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"name">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"port">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Service">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
Service(port: prop(port), name: makestring())
start,v2,v4,v6
```
