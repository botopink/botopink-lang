{module, std@io@http@@Method}.
{exports, [{verb, 1}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 21}.

{function, verb, 1, 3}.
  {label, 2}.
    {line, [{location, "std@io@http@@Method.erl", 1}]}.
    {func_info, {atom, std@io@http@@Method}, {atom, verb}, 1}.
  {label, 3}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 5}, [{x, 0}, {atom, std@io@http@@Method__v__get}]}.
    {move, {literal, <<"GET">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {test, is_eq, {f, 6}, [{x, 0}, {atom, std@io@http@@Method__v__post}]}.
    {move, {literal, <<"POST">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
    {test, is_eq, {f, 7}, [{x, 0}, {atom, std@io@http@@Method__v__put}]}.
    {move, {literal, <<"PUT">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 7}.
    {test, is_eq, {f, 8}, [{x, 0}, {atom, std@io@http@@Method__v__delete}]}.
    {move, {literal, <<"DELETE">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 8}.
    {test, is_eq, {f, 9}, [{x, 0}, {atom, std@io@http@@Method__v__patch}]}.
    {move, {literal, <<"PATCH">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 9}.
    {test, is_eq, {f, 10}, [{x, 0}, {atom, std@io@http@@Method__v__head}]}.
    {move, {literal, <<"HEAD">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 10}.
    {test, is_eq, {f, 11}, [{x, 0}, {atom, std@io@http@@Method__v__options}]}.
    {move, {literal, <<"OPTIONS">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 11}.
    {case_end, {x, 0}}.
  {label, 4}.
    {deallocate, 8}.
    return.

{function, '__bp_format', 1, 13}.
  {label, 12}.
    {line, [{location, "std@io@http@@Method.erl", 2}]}.
    {func_info, {atom, std@io@http@@Method}, {atom, '__bp_format'}, 1}.
  {label, 13}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 14}, [{x, 0}, {atom, std@io@http@@Method__v__get}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Method.Get">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 14}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 15}, [{x, 0}, {atom, std@io@http@@Method__v__post}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Method.Post">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 15}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 16}, [{x, 0}, {atom, std@io@http@@Method__v__put}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Method.Put">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 16}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 17}, [{x, 0}, {atom, std@io@http@@Method__v__delete}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Method.Delete">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 17}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 18}, [{x, 0}, {atom, std@io@http@@Method__v__patch}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Method.Patch">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 18}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 19}, [{x, 0}, {atom, std@io@http@@Method__v__head}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Method.Head">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 19}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 20}, [{x, 0}, {atom, std@io@http@@Method__v__options}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Method.Options">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 20}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Method">>}, nil]}}.
    {deallocate, 2}.
    return.
