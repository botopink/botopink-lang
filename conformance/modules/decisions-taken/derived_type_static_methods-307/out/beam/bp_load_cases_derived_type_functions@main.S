{module, bp_load_cases_derived_type_functions@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__kind', 1}, {'__bp_priv__patched', 2}, {'__bp_priv__titleOf', 1}]}.
{attributes, []}.
{labels, 88}.
%%% Decision 307 — std's `Type` answers a NEW record type at build, bound by a
%%% module-level `val` and named after it: `pick`, `omit`, `partial`,
%%% `required` and `merge`, nested and chained, each usable in every type
%%% position, constructed by its fields, read, printed and matched by name, on
%%% all four targets.
% A derivation of a derivation, and a nested call as the source.

{function, titleOf, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, titleOf}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 20}, [{x, 0}, 2, {atom, bp_load_cases_derived_type_functions@main@@RecipeTitle}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 20}.
    {deallocate, 1}.
    return.

{function, patched, 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, patched}, 2}.
  {label, 5}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 22}, [{x, 0}, 4, {atom, bp_load_cases_derived_type_functions@main@@RecipePatch}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 22}.
    {test, is_ne_exact, {f, 21}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 23}}.
  {label, 21}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 24}, [{x, 0}, 4, {atom, bp_load_cases_derived_type_functions@main@@Recipe}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 24}.
  {label, 23}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 26}, [{x, 0}, 4, {atom, bp_load_cases_derived_type_functions@main@@RecipePatch}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 26}.
    {test, is_ne_exact, {f, 25}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 27}}.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 28}, [{x, 0}, 4, {atom, bp_load_cases_derived_type_functions@main@@Recipe}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 28}.
  {label, 27}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 30}, [{x, 0}, 4, {atom, bp_load_cases_derived_type_functions@main@@RecipePatch}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 30}.
    {test, is_ne_exact, {f, 29}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 31}}.
  {label, 29}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 32}, [{x, 0}, 4, {atom, bp_load_cases_derived_type_functions@main@@Recipe}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 32}.
  {label, 31}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_derived_type_functions@main@@Recipe}, {y, 3}, {y, 5}, {x, 0}]}}.
    {deallocate, 8}.
    return.
% Matched by name: a derived type is its own type, not its source's.

{function, kind, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, kind}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 34}, [{x, 0}, 4, {atom, bp_load_cases_derived_type_functions@main@@DogWithBreed}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 35}}.
  {label, 34}.
    {move, {atom, false}, {x, 0}}.
  {label, 35}.
    {test, is_eq, {f, 33}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"DogWithBreed">>}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 33}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 37}, [{x, 0}, 3, {atom, bp_load_cases_derived_type_functions@main@@Dog}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 38}}.
  {label, 37}.
    {move, {atom, false}, {x, 0}}.
  {label, 38}.
    {test, is_eq, {f, 36}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"Dog">>}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 36}.
    {move, {literal, <<"other">>}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {literal, <<"Feijoada">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_derived_type_functions@main@@RecipeTitle}, {x, 0}]}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, {literal, <<"Moqueca">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_derived_type_functions@main@@RecipeBrief}, {x, 0}, {integer, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 67}, [{x, 0}, 3, {atom, bp_load_cases_derived_type_functions@main@@RecipeBrief}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 67}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, {literal, <<"Feijoada">>}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_derived_type_functions@main@@Recipe}, {x, 0}, {atom, undefined}, {integer, 2}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"black beans">>}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_derived_type_functions@main@@RecipePatch}, {atom, undefined}, {x, 0}, {integer, 6}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 68}, [{x, 0}, 4, {atom, bp_load_cases_derived_type_functions@main@@Recipe}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 68}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 70}, [{x, 0}, 4, {atom, bp_load_cases_derived_type_functions@main@@Recipe}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 70}.
    {test, is_ne_exact, {f, 69}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 71}}.
  {label, 69}.
    {move, {literal, <<"-">>}, {x, 0}}.
  {label, 71}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 72}, [{x, 0}, 4, {atom, bp_load_cases_derived_type_functions@main@@Recipe}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 72}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, {literal, <<"Acaraj\x{C3}\x{A9}">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"fried">>}, {x, 0}}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_derived_type_functions@main@@RecipeFull}, {x, 1}, {x, 0}, {integer, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 73}, [{x, 0}, 4, {atom, bp_load_cases_derived_type_functions@main@@RecipeFull}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 73}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, {literal, <<"Rex">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"mutt">>}, {x, 0}}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_derived_type_functions@main@@DogWithBreed}, {x, 1}, {atom, undefined}, {x, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"Bia">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_derived_type_functions@main@@Dog}, {x, 0}, {integer, 3}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, {literal, <<"Lua">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"beagle">>}, {x, 0}}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_derived_type_functions@main@@DogWithBreed}, {x, 1}, {integer, 3}, {x, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<")">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 74}, [{x, 0}, 4, {atom, bp_load_cases_derived_type_functions@main@@DogWithBreed}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 74}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<" (">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 75}, [{x, 0}, 4, {atom, bp_load_cases_derived_type_functions@main@@DogWithBreed}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 75}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 77}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, {literal, <<"Lua">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"poodle">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"calm">>}, {x, 0}}.
    {test_heap, 6, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_derived_type_functions@main@@NotedDog}, {x, 1}, {integer, 1}, {x, 2}, {x, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 80}, [{x, 0}, 5, {atom, bp_load_cases_derived_type_functions@main@@NotedDog}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 80}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, {literal, <<"Vatap\x{C3}\x{A1}">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_derived_type_functions@main@@TitleOnly}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 81}, [{x, 0}, 2, {atom, bp_load_cases_derived_type_functions@main@@TitleOnly}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 81}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, {literal, <<"Bob\x{C3}\x{B3}">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_derived_type_functions@main@@RecipeTitle}, {x, 0}]}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_loaded_main', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {call, 0, {f, 9}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/derived_type_functions|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, '_botopink_main'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 9}, 0}.

{function, main, 1, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, main}, 1}.
  {label, 19}.
    {call_only, 0, {f, 17}}.

{function, '__bp_priv__kind', 1, 83}.
  {label, 82}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, '__bp_priv__kind'}, 1}.
  {label, 83}.
    {call_only, 1, {f, 7}}.

{function, '__bp_priv__patched', 2, 85}.
  {label, 84}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, '__bp_priv__patched'}, 2}.
  {label, 85}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__titleOf', 1, 87}.
  {label, 86}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, '__bp_priv__titleOf'}, 1}.
  {label, 87}.
    {call_only, 1, {f, 3}}.

{function, '__bp_print', 1, 40}.
  {label, 39}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, '__bp_print'}, 1}.
  {label, 40}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 44}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 44}.
  {label, 43}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 44}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 42}}.

{function, '-bp_show_elem-', 1, 46}.
  {label, 45}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 46}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 42}}.

{function, '__bp_show', 2, 42}.
  {label, 41}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, '__bp_show'}, 2}.
  {label, 42}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 54}, [{x, 0}]}.
    {test, is_eq, {f, 53}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 53}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 54}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 55}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 46}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 55}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 57}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 56}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 56}, [{x, 0}]}.
    {test, is_ne_exact, {f, 56}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 56}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 56}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 61}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 62}}.
  {label, 61}.
    {test, is_eq_exact, {f, 58}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 62}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 42}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 56}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 46}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 57}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 59}, [{x, 0}]}.
    {test, is_ne_exact, {f, 59}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 59}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 60}, [{x, 0}, {atom, undefined}]}.
  {label, 58}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 48}, 2}.
  {label, 59}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 60}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 48}.
  {label, 47}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, '__bp_tagged'}, 2}.
  {label, 48}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 63}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 63}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 63}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 50}, 3}.
  {label, 64}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 50}.
  {label, 49}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, '__bp_render'}, 1}.
  {label, 50}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 65}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 65}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 66}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 66}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 52}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 52}.
  {label, 51}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 52}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 42}}.
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

{function, '-bp_stringify-', 1, 77}.
  {label, 76}.
    {line, [{location, "bp_load_cases_derived_type_functions@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_derived_type_functions@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 77}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 78}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 78}.
    {test, is_integer, {f, 79}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 79}.
    {call, 1, {f, 44}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
