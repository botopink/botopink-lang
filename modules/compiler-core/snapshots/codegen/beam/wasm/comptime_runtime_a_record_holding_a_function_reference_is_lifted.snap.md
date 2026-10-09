----- SOURCE CODE -- main.bp
```botopink
type Op(name: string, run: fn() -> i32, twice: fn() -> i32)

fn two() -> i32 {
    return 2;
}

fn main() {
    val op = comptime Op(name: "two" + "!", run: two, twice: { -> two() * 2 });
    @print(op.name);
    @print(op.run());
    @print(op.twice());
}
```

----- COMPTIME BEAM ASSEMBLY -- comptime block
```erlang
{module, comptime_module}.
{exports, [{main, 1}]}.
{attributes, []}.
{labels, 83}.

{function, '__bp_ct_value', 0, 2}.
  {label, 1}.
    {func_info, {atom, comptime_module}, {atom, '__bp_ct_value'}, 0}.
  {label, 2}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {literal, <<"two">>}, {x, 0}}.
    {move, {literal, <<"!">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 4}}.
    {move, {x, 0}, {y, 1}}.
    {call, 0, {f, 6}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, name}, {y, 0}, {atom, run}, {y, 1}, {atom, twice}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-__bp_fn_0/0-fun-0-', 0, 22}.
  {label, 21}.
    {func_info, {atom, comptime_module}, {atom, '-__bp_fn_0/0-fun-0-'}, 0}.
  {label, 22}.
    {allocate, 0, 0}.
    {call_last, 0, {f, 8}, 0}.

{function, '__bp_fn_0', 0, 4}.
  {label, 3}.
    {func_info, {atom, comptime_module}, {atom, '__bp_fn_0'}, 0}.
  {label, 4}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 22}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '-__bp_fn_1/0-fun-1-', 0, 28}.
  {label, 27}.
    {func_info, {atom, comptime_module}, {atom, '-__bp_fn_1/0-fun-1-'}, 0}.
  {label, 28}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {call, 0, {f, 8}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '*', 2}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_fn_1', 0, 6}.
  {label, 5}.
    {func_info, {atom, comptime_module}, {atom, '__bp_fn_1'}, 0}.
  {label, 6}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 28}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, two, 0, 8}.
  {label, 7}.
    {func_info, {atom, comptime_module}, {atom, two}, 0}.
  {label, 8}.
    {allocate, 0, 0}.
    {move, {integer, 2}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, main, 1, 10}.
  {label, 9}.
    {func_info, {atom, comptime_module}, {atom, main}, 1}.
  {label, 10}.
    {allocate, 9, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 2}}.
    {'try', {y, 8}, {f, 35}}.
    {call, 0, {f, 2}}.
    {move, {x, 0}, {y, 4}}.
    {call, 0, {f, 12}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 14}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"value">>}, {atom, value}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {try_end, {y, 8}}.
    {jump, {f, 36}}.
  {label, 35}.
    {try_case, {y, 8}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 1}, {y, 5}}.
    {move, {x, 2}, {y, 6}}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 5}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_decorator, '__bp_text', 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"error">>}, {atom, message}, {y, 7}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 3}}.
    {jump, {f, 37}}.
  {label, 37}.
  {label, 36}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 9}.
    return.

{function, '__bp_fns', 0, 12}.
  {label, 11}.
    {func_info, {atom, comptime_module}, {atom, '__bp_fns'}, 0}.
  {label, 12}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {call, 0, {f, 4}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{integer, 0}, {y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 6}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{integer, 1}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-__bp_lift/2-fun-2-', 3, 70}.
  {label, 69}.
    {func_info, {atom, comptime_module}, {atom, '-__bp_lift/2-fun-2-'}, 3}.
  {label, 70}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {x, 2}, {y, 0}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 14}, 3}.

{function, '__bp_lift', 2, 14}.
  {label, 13}.
    {func_info, {atom, comptime_module}, {atom, '__bp_lift'}, 2}.
  {label, 14}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, null}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 44}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 45}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 45}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 46}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 46}.
    {move, {y, 2}, {x, 0}}.
    {test, is_integer, {f, 47}, [{x, 0}]}.
    {jump, {f, 48}}.
  {label, 48}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 47}.
    {move, {y, 2}, {x, 0}}.
    {test, is_float, {f, 49}, [{x, 0}]}.
    {jump, {f, 50}}.
  {label, 50}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"float">>}, {y, 2}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 49}.
    {move, {y, 2}, {x, 0}}.
    {test, is_binary, {f, 51}, [{x, 0}]}.
    {jump, {f, 52}}.
  {label, 52}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 51}.
    {move, {y, 2}, {x, 0}}.
    {test, is_atom, {f, 53}, [{x, 0}]}.
    {jump, {f, 54}}.
  {label, 54}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_binary, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"atom">>}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 53}.
    {move, {y, 2}, {x, 0}}.
    {test, is_list, {f, 55}, [{x, 0}]}.
    {jump, {f, 56}}.
  {label, 56}.
    {move, nil, {y, 4}}.
    {move, {y, 2}, {y, 5}}.
  {label, 58}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nonempty_list, {f, 59}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 6}, {y, 5}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 14}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 2, 0}.
    {put_list, {y, 7}, {y, 4}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 58}}.
  {label, 59}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nil, {f, 60}, [{x, 0}]}.
    {jump, {f, 57}}.
  {label, 60}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 57}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 55}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 61}, [{x, 0}]}.
    {jump, {f, 62}}.
  {label, 62}.
    {move, nil, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
  {label, 64}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nonempty_list, {f, 65}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 7}, {y, 5}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 14}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 2, 0}.
    {put_list, {y, 8}, {y, 4}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 64}}.
  {label, 65}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nil, {f, 66}, [{x, 0}]}.
    {jump, {f, 63}}.
  {label, 66}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 63}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"tuple">>}, {y, 5}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 61}.
    {move, {y, 2}, {x, 0}}.
    {test, is_map, {f, 67}, [{x, 0}]}.
    {jump, {f, 68}}.
  {label, 68}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 70}, 2, 0, {x, 0}, {list, [{y, 3}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, map, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"record">>}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 67}.
    {move, {y, 2}, {x, 0}}.
    {test, is_function, {f, 73}, [{x, 0}]}.
    {jump, {f, 74}}.
  {label, 74}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 16}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"fn">>}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 73}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_decorator, '__bp_text', 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"resource">>}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 9}.
    return.

{function, '__bp_fn_index', 2, 16}.
  {label, 15}.
    {func_info, {atom, comptime_module}, {atom, '__bp_fn_index'}, 2}.
  {label, 16}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 79}, [{x, 0}, nil]}.
    {move, {atom, null}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 79}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 80}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 80}, [{x, 0}]}.
    {test, test_arity, {f, 80}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test, is_eq_exact, {f, 80}, [{x, 0}, {x, 1}]}.
    {jump, {f, 81}}.
  {label, 81}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 80}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 82}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 6}}.
    {move, {y, 6}, {y, 2}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_last, 2, {f, 16}, 9}.
  {label, 82}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
```

----- COMPTIME REPLY -- comptime block
```json
{
  "kind": "value",
  "value": {
    "record": {
      "name": "two!",
      "run": {
        "fn": 0
      },
      "twice": {
        "fn": 1
      }
    }
  }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (table funcref (elem $__fnref_two $__lambda1))
  (data (i32.const 256) "\17\00\00\00R\02Op\03\04names\03runi\05twicei")
  (data (i32.const 284) "\04\00\00\00two!")
  (global $__heap_ptr (mut i32) (i32.const 292))
  (func $two (result i32)
    i32.const 2
    return
  )
  (func $main
    (local $__mem0 i32)
    (local $op i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__fnv0 i32)
    (local $__fnv1 i32)
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 284
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 0
    i32.store
    local.get $__mem1
    i32.store offset=8
    local.get $__mem0
    i32.const 4
    call $__alloc
    local.set $__mem2
    local.get $__mem2
    i32.const 1
    i32.store
    local.get $__mem2
    i32.store offset=12
    local.get $__mem0
    i32.const 4
    i32.add
    local.set $op
    local.get $op
    i32.load ;; .name
    call $__print_str
    local.get $op
    i32.load offset=4 ;; .run
    local.set $__fnv0
    local.get $__fnv0
    local.get $__fnv0
    i32.load ;; table index
    call_indirect (param i32) (result i32)
    call $__print_i32
    local.get $op
    i32.load offset=8 ;; .twice
    local.set $__fnv1
    local.get $__fnv1
    local.get $__fnv1
    i32.load ;; table index
    call_indirect (param i32) (result i32)
    call $__print_i32
  )
  (func $__fnref_two (param $__env i32) (result i32)
    call $two
  )
  (func $__lambda1 (param $__env i32) (result i32)
    call $two
    i32.const 2
    call $__i32_mul_chk
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
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
  (func $__alloc (param $n i32) (result i32)
    (local $p i32) (local $e i32)
    global.get $__heap_ptr
    local.set $p
    local.get $p
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    local.set $e
    local.get $e
    local.get $p
    i32.lt_u
    (if
      (then
        unreachable
      )
    )
    local.get $e
    memory.size
    i32.const 16
    i32.shl
    i32.gt_u
    (if
      (then
        local.get $e
        i32.const 65535
        i32.add
        i32.const 16
        i32.shr_u
        memory.size
        i32.sub
        memory.grow
        i32.const -1
        i32.eq
        (if
          (then
            unreachable
          )
        )
      )
    )
    local.get $e
    global.set $__heap_ptr
    local.get $p
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.add
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.sub
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.mul
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.add
    local.set $r
    local.get $a
    local.get $r
    i64.xor
    local.get $b
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.sub
    local.set $r
    local.get $a
    local.get $b
    i64.xor
    local.get $a
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (result i64)
    (local $r i64)
    local.get $a
    i64.const -1
    i64.eq
    local.get $b
    i64.const -9223372036854775808
    i64.eq
    i32.and
    (if
      (then
        unreachable
      )
    )
    local.get $a
    local.get $b
    i64.mul
    local.set $r
    local.get $a
    i64.eqz
    i32.eqz
    (if
      (then
        local.get $r
        local.get $a
        i64.div_s
        local.get $b
        i64.ne
        (if
          (then
            unreachable
          )
        )
      )
    )
    local.get $r
  )
)
```

----- RUN LOG -----
```logs
two!
2
4
```
