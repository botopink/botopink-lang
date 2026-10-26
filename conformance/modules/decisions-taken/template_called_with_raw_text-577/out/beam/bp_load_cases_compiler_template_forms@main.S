{module, bp_load_cases_compiler_template_forms@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {find, 0}, {digits, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__array_first', 1}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}]}.
{attributes, []}.
{labels, 114}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 26}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 27}}.
  {label, 26}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 28}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 29}}.
  {label, 28}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 31}}.
  {label, 29}.
  {label, 27}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 32}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 33}}.
  {label, 32}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 34}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 31}}.
    {jump, {f, 35}}.
  {label, 34}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 31}}.
  {label, 35}.
  {label, 33}.
    {deallocate, 6}.
    return.
%%% Decisions 577 (2), (3), 578 (1) — a template is called with its text in
%%% three places: `` name @`…` ``, `` recv.name @`…` `` for a template method
%%% (its `syntax self: R` receiver first), and the annotation `` #[name @`…`] ``,
%%% whose second `syntax` parameter is the annotated declaration.

{function, find, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, find}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {integer, 1}, {x, 0}}.
    {deallocate, 0}.
    return.
% The number the text writes, read at build.

{function, digits, 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, digits}, 1}.
  {label, 9}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 5}]}.
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 39}}.
    {test, is_lt, {f, 37}, [{y, 2}, {x, 0}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {integer, 10}], {x, 0}}.
    {test, is_ge, {f, 40}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 40}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 41}}.
  {label, 40}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:27:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 41}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 43}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 53}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 53}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 54}}.
  {label, 53}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:27:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 54}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 48}], {x, 0}}.
    {test, is_ge, {f, 55}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 55}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 56}}.
  {label, 55}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/main.bp:27:41">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 56}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 57}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 57}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 58}}.
  {label, 57}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:28:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 58}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 36}}.
  {label, 37}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, main, 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, main}, 0}.
  {label, 11}.
    {allocate, 5, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"select * from users">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_compiler_template_forms@main@@Query}, {x, 0}]}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 61}}.
    {test, is_eq, {f, 62}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 64}}.
  {label, 62}.
    {test, is_tagged_tuple, {f, 63}, [{x, 0}, 2, {atom, bp_load_cases_compiler_template_forms@main@@Query}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 64}}.
  {label, 63}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 64}.
    {test, is_ne_exact, {f, 59}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 65}}.
  {label, 59}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 65}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 67}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_compiler_template_forms@main@@Num}, {integer, 1}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 94}, [{x, 0}, 2, {atom, bp_load_cases_compiler_template_forms@main@@Num}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 94}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 41}], {x, 0}}.
    {test, is_ge, {f, 95}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 95}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 96}}.
  {label, 95}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:41:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 96}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_compiler_template_forms@main@@Num}, {x, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 97}, [{x, 0}, 2, {atom, bp_load_cases_compiler_template_forms@main@@Num}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 97}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_loaded_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {call, 0, {f, 11}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/compiler_template_forms|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '_botopink_main'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 23}}.
    {call_last, 0, {f, 11}, 0}.

{function, main, 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, main}, 1}.
  {label, 21}.
    {call_only, 0, {f, 19}}.

{function, '__bp_load_siblings', 0, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 23}.
    {allocate, 0, 0}.
    {move, {atom, bp_load_cases_compiler_template_forms@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 98}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 25}, 0}.
  {label, 98}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 25}.
    {test, is_nonempty_list, {f, 99}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 100}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 102}}.
  {label, 100}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 101}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 102}}.
  {label, 101}.
    {test_heap, 4, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 1}}.
    {move, {literal, <<"error: ~ts does not compile - refusing to run~n  ~p~n">>}, {x, 0}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, standard_error}, {x, 0}}.
    {call_ext, 2, {extfunc, file, write, 2}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, halt, 1}}.
  {label, 102}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 25}, 2}.
  {label, 99}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, 'array_first', 1, 61}.
  {label, 60}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, 'array_first'}, 1}.
  {label, 61}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_last, 2, {f, 104}, 1}.

{function, '__bp_priv__array_first', 1, 109}.
  {label, 108}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '__bp_priv__array_first'}, 1}.
  {label, 109}.
    {call_only, 1, {f, 61}}.

{function, '__bp_priv__array_range', 2, 111}.
  {label, 110}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 111}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 113}.
  {label, 112}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 17}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 113}.
    {call_only, 2, {f, 5}}.

{function, '__bp_tpl_0', 1, 39}.
  {label, 38}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 39}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 2}.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 47}.
  {label, 46}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 47}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {call_ext, 2, {extfunc, unicode, characters_to_list, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 51}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test, is_lt, {f, 51}, [{x, 0}, {x, 1}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {test, is_ge, {f, 51}, [{x, 0}, {x, 1}]}.
    {jump, {f, 52}}.
  {label, 52}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 5}.
  {label, 51}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_1', 2, 43}.
  {label, 42}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '__bp_tpl_1'}, 2}.
  {label, 43}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 47}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_print', 1, 67}.
  {label, 66}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '__bp_print'}, 1}.
  {label, 67}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 71}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 71}.
  {label, 70}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 71}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 69}}.

{function, '-bp_show_elem-', 1, 73}.
  {label, 72}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 73}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 69}}.

{function, '__bp_show', 2, 69}.
  {label, 68}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '__bp_show'}, 2}.
  {label, 69}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 81}, [{x, 0}]}.
    {test, is_eq, {f, 80}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 80}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 81}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 82}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 73}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 82}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 84}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 83}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 83}, [{x, 0}]}.
    {test, is_ne_exact, {f, 83}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 83}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 83}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 88}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 89}}.
  {label, 88}.
    {test, is_eq_exact, {f, 85}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 89}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 69}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 83}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 73}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 84}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 86}, [{x, 0}]}.
    {test, is_ne_exact, {f, 86}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 86}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 87}, [{x, 0}, {atom, undefined}]}.
  {label, 85}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 75}, 2}.
  {label, 86}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 87}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 75}.
  {label, 74}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '__bp_tagged'}, 2}.
  {label, 75}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 90}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 90}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 90}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 91}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 77}, 3}.
  {label, 91}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 77}.
  {label, 76}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '__bp_render'}, 1}.
  {label, 77}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 92}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 92}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 93}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 93}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 79}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 79}.
  {label, 78}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 79}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 69}}.
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

{function, '-bp_at-', 2, 104}.
  {label, 103}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '-bp_at-'}, 2}.
  {label, 104}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 106}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 105}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 106}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 105}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 105}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_prim_append', 2, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_compiler_template_forms@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_compiler_template_forms@main}, {atom, '__bp_prim_append'}, 2}.
  {label, 31}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 107}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 107}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
