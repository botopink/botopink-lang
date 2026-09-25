----- SOURCE CODE -- main.bp
```botopink
val HttpMethod = type {
    Get,
    Post,
    Put,
    Delete,
    fn name(m: Self) -> string {
        val label = case m {
            Get -> "GET";
            Post -> "POST";
            Put -> "PUT";
            _ -> "DELETE";
        };
        return label;
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 2}.
```

----- BEAM ASSEMBLY -- test@main@@HttpMethod.S
```erlang
{module, test@main@@HttpMethod}.
{exports, [{name, 1}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 14}.

{function, name, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main@@HttpMethod.erl", 1}]}.
    {func_info, {atom, test@main@@HttpMethod}, {atom, name}, 1}.
  {label, 3}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 5}, [{x, 0}, {atom, test@main@@HttpMethod__v__get}]}.
    {move, {literal, <<"GET">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {test, is_eq, {f, 6}, [{x, 0}, {atom, test@main@@HttpMethod__v__post}]}.
    {move, {literal, <<"POST">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
    {test, is_eq, {f, 7}, [{x, 0}, {atom, test@main@@HttpMethod__v__put}]}.
    {move, {literal, <<"PUT">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 7}.
    {move, {literal, <<"DELETE">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_format', 1, 9}.
  {label, 8}.
    {line, [{location, "test@main@@HttpMethod.erl", 2}]}.
    {func_info, {atom, test@main@@HttpMethod}, {atom, '__bp_format'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 10}, [{x, 0}, {atom, test@main@@HttpMethod__v__get}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HttpMethod.Get">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 10}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 11}, [{x, 0}, {atom, test@main@@HttpMethod__v__post}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HttpMethod.Post">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 11}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 12}, [{x, 0}, {atom, test@main@@HttpMethod__v__put}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HttpMethod.Put">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 12}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 13}, [{x, 0}, {atom, test@main@@HttpMethod__v__delete}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HttpMethod.Delete">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 13}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HttpMethod">>}, nil]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
