{module, conformance_lib@sections}.
{exports, [{'HEADER', 0}, {targets, 0}, {headerOf, 2}, {parseFile, 1}, {renderFile, 1}, {find, 3}, {answeringTarget, 3}, {same, 5}, {renderCandidate, 5}, {'__bp_priv__array_any', 2}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__string_slice', 3}, {'__bp_priv__badBody', 1}, {'__bp_priv__fail', 2}, {'__bp_priv__isTarget', 1}, {'__bp_priv__sectionOf', 3}, {'__bp_priv__snapOfSection', 1}]}.
{attributes, []}.
{labels, 300}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "conformance_lib@sections.erl", 1}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 34}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 35}}.
  {label, 34}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 36}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 37}}.
  {label, 36}.
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
    {call, 2, {f, 39}}.
  {label, 37}.
  {label, 35}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "conformance_lib@sections.erl", 2}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 40}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 41}}.
  {label, 40}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 42}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 39}}.
    {jump, {f, 43}}.
  {label, 42}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 39}}.
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
    {call, 2, {f, 39}}.
  {label, 43}.
  {label, 41}.
    {deallocate, 6}.
    return.
%%% A module's `snapshot/main.snap` (decision 989 (5)): the sectioned file.
%%% 
%%%     botopink-cell 2                 the format and its version, always line 1
%%%     == <case>                       the case's answer on every target, the records of
%%%     out 1                             `records.bp`, one run per section
%%%     == <case> on <t>                the case's answer on target <t> alone (a departure;
%%%     out 2                             <t> one of commonJS, erlang, beam, wasm)
%%% 
%%% A case with no departure for the target it runs on answers its plain section on that target; a
%%% departure replaces the plain section whole (decision 475 (3), per case). A section's body is the
%%% text between its header and the next, kept as written: `parseFile` accepts only a file whose
%%% every body is the canonical spelling of its records, so `renderFile(parseFile(text))` is the
%%% file byte for byte. A `== ` line is never a record, so a body never swallows a header.
%% Line 1 of the sectioned file.

{function, 'HEADER', 0, 7}.
  {label, 6}.
    {line, [{location, "conformance_lib@sections.erl", 3}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, 'HEADER'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {literal, <<"botopink-cell 2">>}, {x, 0}}.
    {deallocate, 0}.
    return.
%% The targets a departure names.

{function, targets, 0, 9}.
  {label, 8}.
    {line, [{location, "conformance_lib@sections.erl", 4}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, targets}, 0}.
  {label, 9}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"wasm">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"beam">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"erlang">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"commonJS">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 1}.
    return.
%% One section: the case, the target it departs on (`null` for the plain one) and its records as written.
%% The sectioned file, in file order.

{function, fail, 2, 11}.
  {label, 10}.
    {line, [{location, "conformance_lib@sections.erl", 5}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, fail}, 2}.
  {label, 11}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Malformed}, {y, 0}, {y, 1}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.

{function, isTarget, 1, 13}.
  {label, 12}.
    {line, [{location, "conformance_lib@sections.erl", 6}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, isTarget}, 1}.
  {label, 13}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 9}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 47}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 45}, 3}.
%% The header line of a section.

{function, headerOf, 2, 15}.
  {label, 14}.
    {line, [{location, "conformance_lib@sections.erl", 7}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, headerOf}, 2}.
  {label, 15}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_ne_exact, {f, 50}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<" on ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"== ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 80}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 5}.
    return.
  {label, 50}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"== ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 80}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 5}.
    return.
%% Why a section's body is not its records' one spelling (`""` when it is).

{function, badBody, 1, 17}.
  {label, 16}.
    {line, [{location, "conformance_lib@sections.erl", 8}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, badBody}, 1}.
  {label, 17}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 83}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 83}.
    {call_ext, 1, {extfunc, conformance_lib@records, parseBody, 1}}.
    {test, is_tagged_tuple, {f, 85}, [{x, 0}, 2, {atom, ok}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 84}}.
  {label, 85}.
    {test, is_tagged_tuple, {f, 86}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 87}, [{x, 0}, 3, {atom, conformance_lib@records@@Malformed}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 87}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<": ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 88}, [{x, 0}, 3, {atom, conformance_lib@records@@Malformed}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 88}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"` line ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 89}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 89}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 90}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 90}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 15}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"section `">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 80}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 84}}.
  {label, 86}.
    {case_end, {x, 0}}.
  {label, 84}.
    {deallocate, 3}.
    return.
%% Parse a sectioned file; a malformed one answers its 1-based line and the reason.

{function, parseFile, 1, 19}.
  {label, 18}.
    {line, [{location, "conformance_lib@sections.erl", 9}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, parseFile}, 1}.
  {label, 19}.
    {allocate, 41, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}, {y, 35}, {y, 36}, {y, 37}, {y, 38}, {y, 39}, {y, 40}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 92}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 93}}.
  {label, 92}.
    {move, {atom, false}, {x, 0}}.
  {label, 93}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 94}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 97}}.
    {test, is_eq, {f, 111}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 112}}.
  {label, 111}.
    {move, {atom, true}, {x, 0}}.
  {label, 112}.
    {jump, {f, 95}}.
  {label, 94}.
    {move, {atom, true}, {x, 0}}.
  {label, 95}.
    {test, is_eq, {f, 91}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 114}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"every line ends with a newline">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 11}, 41}.
  {label, 91}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 132}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 132}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 133}}.
  {label, 132}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/sections.bp:65:43">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 133}.
    {move, {integer, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 131}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 114}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 137}}.
    {test, is_ne_exact, {f, 135}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 140}}.
  {label, 135}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 140}.
    {move, {x, 0}, {y, 3}}.
    {call, 0, {f, 7}}.
    {test, is_ne_exact, {f, 134}, [{y, 3}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"`">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {call, 0, {f, 7}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"line 1 must be `">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 80}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_last, 2, {f, 11}, 41}.
  {label, 134}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {line, [{location, "conformance_lib@sections.erl", 10}]}.
  {label, 141}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 142}, [{y, 10}, {x, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call, 2, {f, 137}}.
    {test, is_ne_exact, {f, 143}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {jump, {f, 144}}.
  {label, 143}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 144}.
    {move, {x, 0}, {y, 12}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 10}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 145}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 145}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 146}}.
  {label, 145}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/sections.bp:76:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 146}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, <<"== ">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 148}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 149}}.
  {label, 148}.
    {move, {atom, true}, {x, 0}}.
  {label, 149}.
    {test, is_eq, {f, 147}, [{x, 0}, {atom, true}]}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq, {f, 150}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@sections@@Section}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 151}}.
  {label, 150}.
  {label, 151}.
    {move, {y, 12}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 3, {f, 131}}.
    {move, {x, 0}, {y, 14}}.
    {move, {literal, <<" on ">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 14}, {x, 0}}.
    {call, 2, {f, 153}}.
    {move, {x, 0}, {y, 15}}.
    {test, is_lt, {f, 166}, [{y, 15}, {integer, 0}]}.
    {move, {y, 14}, {x, 0}}.
    {jump, {f, 167}}.
  {label, 166}.
    {move, {y, 14}, {x, 0}}.
    {move, {y, 15}, {x, 2}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 3, {f, 131}}.
  {label, 167}.
    {move, {x, 0}, {y, 16}}.
    {test, is_lt, {f, 168}, [{y, 15}, {integer, 0}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 169}}.
  {label, 168}.
    {gc_bif, '+', {f, 0}, 0, [{y, 15}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 170}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 170}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 171}}.
  {label, 170}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/sections.bp:83:58">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 171}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {y, 14}, {x, 0}}.
    {call, 3, {f, 131}}.
  {label, 169}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 173}, [{y, 16}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 174}}.
  {label, 173}.
    {move, {atom, false}, {x, 0}}.
  {label, 174}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 175}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 16}, {x, 0}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 177}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 178}}.
  {label, 177}.
    {move, {atom, true}, {x, 0}}.
  {label, 178}.
    {jump, {f, 176}}.
  {label, 175}.
    {move, {atom, true}, {x, 0}}.
  {label, 176}.
    {test, is_eq, {f, 172}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"a section names one case: `== <case>` or `== <case> on <target>`">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 10}, {x, 0}}.
    {call_last, 2, {f, 11}, 41}.
  {label, 172}.
    {test, is_eq_exact, {f, 180}, [{y, 7}, {atom, undefined}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 181}}.
  {label, 180}.
    {move, {atom, false}, {x, 0}}.
  {label, 181}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 182}, [{x, 1}, {atom, true}]}.
    {move, {y, 7}, {x, 0}}.
    {call, 1, {f, 13}}.
    {jump, {f, 183}}.
  {label, 182}.
    {move, {atom, true}, {x, 0}}.
  {label, 183}.
    {test, is_eq, {f, 184}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 185}}.
  {label, 184}.
    {move, {atom, true}, {x, 0}}.
  {label, 185}.
    {test, is_eq, {f, 179}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"a departure names commonJS, erlang, beam or wasm">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 10}, {x, 0}}.
    {call_last, 2, {f, 11}, 41}.
  {label, 179}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 188}, 0, 0, {x, 0}, {list, [{y, 16}, {y, 7}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call, 2, {f, 45}}.
    {test, is_eq, {f, 186}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"a section is written once">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 10}, {x, 0}}.
    {call_last, 2, {f, 11}, 41}.
  {label, 186}.
    {move, {y, 16}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 197}}.
  {label, 147}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq, {f, 199}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 200}}.
  {label, 199}.
    {move, {atom, true}, {x, 0}}.
  {label, 200}.
    {test, is_eq, {f, 198}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"records come after a `== <case>` line">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 10}, {x, 0}}.
    {call_last, 2, {f, 11}, 41}.
  {label, 198}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 17}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 12}, {x, 0}}.
    {move, {y, 17}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 17}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 80}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
  {label, 197}.
    {jump, {f, 141}}.
  {label, 142}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq, {f, 201}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 18}}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@sections@@Section}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {y, 18}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 202}}.
  {label, 201}.
  {label, 202}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 19}}.
    {line, [{location, "conformance_lib@sections.erl", 10}]}.
  {label, 203}.
    {move, {y, 5}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 204}, [{y, 19}, {x, 0}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 19}, {x, 1}}.
    {call, 2, {f, 137}}.
    {test, is_ne_exact, {f, 205}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 20}, {x, 0}}.
    {jump, {f, 206}}.
  {label, 205}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@sections@@Section}, {x, 1}, {atom, undefined}, {x, 0}]}}.
  {label, 206}.
    {move, {x, 0}, {y, 21}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 19}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 207}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 207}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 208}}.
  {label, 207}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/sections.bp:104:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 208}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 21}, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {x, 0}, {y, 22}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 209}, [{y, 22}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 22}, {x, 1}}.
    {call_last, 2, {f, 11}, 41}.
  {label, 209}.
    {jump, {f, 203}}.
  {label, 204}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@sections@@SnapFile}, {y, 5}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 41}.
    return.
%% The file's text: the header, then each section's header line and body.

{function, renderFile, 1, 21}.
  {label, 20}.
    {line, [{location, "conformance_lib@sections.erl", 10}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, renderFile}, 1}.
  {label, 21}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {call, 0, {f, 7}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 80}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 215}, [{x, 0}, 2, {atom, conformance_lib@sections@@SnapFile}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 215}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 211}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, sectionOf, 3, 23}.
  {label, 22}.
    {line, [{location, "conformance_lib@sections.erl", 11}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, sectionOf}, 3}.
  {label, 23}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 227}, [{x, 0}, 2, {atom, conformance_lib@sections@@SnapFile}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 227}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 217}, 0, 0, {x, 0}, {list, [{y, 1}, {y, 2}]}}.
    {'try', {y, 3}, {f, 228}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {try_end, {y, 3}}.
    {jump, {f, 231}}.
  {label, 228}.
    {try_case, {y, 3}}.
    {test, is_eq_exact, {f, 230}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 229}, [{x, 1}, 2, {atom, '__bp_try'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 229}.
    {test, is_tagged_tuple, {f, 230}, [{x, 1}, 2, {atom, '__bp_return'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 230}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 231}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 4}.
    return.
%% The section a case answers on `target`: its departure there when it has one, else its plain section.

{function, find, 3, 25}.
  {label, 24}.
    {line, [{location, "conformance_lib@sections.erl", 12}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, find}, 3}.
  {label, 25}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 23}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_ne_exact, {f, 232}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 232}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 23}, 5}.
%% The target of the section `find` would answer: `target` when the case departs there, else `null`.

{function, answeringTarget, 3, 27}.
  {label, 26}.
    {line, [{location, "conformance_lib@sections.erl", 13}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, answeringTarget}, 3}.
  {label, 27}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 23}}.
    {test, is_ne_exact, {f, 233}, [{x, 0}, {atom, undefined}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 233}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, snapOfSection, 1, 29}.
  {label, 28}.
    {line, [{location, "conformance_lib@sections.erl", 14}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, snapOfSection}, 1}.
  {label, 29}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_ne_exact, {f, 234}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 237}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 237}.
    {call_ext, 1, {extfunc, conformance_lib@records, parseBody, 1}}.
    {test, is_tagged_tuple, {f, 235}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 236}}.
  {label, 235}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 236}.
    {deallocate, 2}.
    return.
  {label, 234}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.
%% Whether the observed answer of `name` on `target` is the accepted one (`records.matches`):
%% a case the file does not have is not equal.

{function, same, 5, 31}.
  {label, 30}.
    {line, [{location, "conformance_lib@sections.erl", 15}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, same}, 5}.
  {label, 31}.
    {allocate, 7, 5}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {x, 4}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 25}}.
    {call, 1, {f, 29}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_ne_exact, {f, 238}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 4}, {x, 2}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext_last, 3, {extfunc, conformance_lib@records, matches, 3}, 7}.
  {label, 238}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 7}.
    return.
%% The candidate section for an observed answer: its header line and its records. The accepted
%% section's `stderr` claims that still hold are kept; a candidate never invents one.

{function, renderCandidate, 5, 33}.
  {label, 32}.
    {line, [{location, "conformance_lib@sections.erl", 16}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, renderCandidate}, 5}.
  {label, 33}.
    {allocate, 9, 5}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {x, 4}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 25}}.
    {call, 1, {f, 29}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_ext, 3, {extfunc, conformance_lib@records, candidate, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, conformance_lib@records, renderBody, 1}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 27}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 15}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 80}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 9}.
    return.

{function, 'array_any', 2, 45}.
  {label, 44}.
    {line, [{location, "conformance_lib@sections.erl", 17}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, 'array_any'}, 2}.
  {label, 45}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 239}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 240}}.
  {label, 239}.
    {move, {atom, false}, {x, 0}}.
  {label, 240}.
    {deallocate, 2}.
    return.

{function, 'string_slice', 3, 131}.
  {label, 130}.
    {line, [{location, "conformance_lib@sections.erl", 18}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, 'string_slice'}, 3}.
  {label, 131}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 241}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 243}, 3}.
  {label, 241}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 265}, 3}.

{function, '__bp_priv__array_any', 2, 283}.
  {label, 282}.
    {line, [{location, "conformance_lib@sections.erl", 20}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_priv__array_any'}, 2}.
  {label, 283}.
    {call_only, 2, {f, 45}}.

{function, '__bp_priv__array_range', 2, 285}.
  {label, 284}.
    {line, [{location, "conformance_lib@sections.erl", 21}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 285}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 287}.
  {label, 286}.
    {line, [{location, "conformance_lib@sections.erl", 22}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 287}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__string_slice', 3, 289}.
  {label, 288}.
    {line, [{location, "conformance_lib@sections.erl", 23}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 289}.
    {call_only, 3, {f, 131}}.

{function, '__bp_priv__badBody', 1, 291}.
  {label, 290}.
    {line, [{location, "conformance_lib@sections.erl", 24}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_priv__badBody'}, 1}.
  {label, 291}.
    {call_only, 1, {f, 17}}.

{function, '__bp_priv__fail', 2, 293}.
  {label, 292}.
    {line, [{location, "conformance_lib@sections.erl", 25}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_priv__fail'}, 2}.
  {label, 293}.
    {call_only, 2, {f, 11}}.

{function, '__bp_priv__isTarget', 1, 295}.
  {label, 294}.
    {line, [{location, "conformance_lib@sections.erl", 26}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_priv__isTarget'}, 1}.
  {label, 295}.
    {call_only, 1, {f, 13}}.

{function, '__bp_priv__sectionOf', 3, 297}.
  {label, 296}.
    {line, [{location, "conformance_lib@sections.erl", 27}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_priv__sectionOf'}, 3}.
  {label, 297}.
    {call_only, 3, {f, 23}}.

{function, '__bp_priv__snapOfSection', 1, 299}.
  {label, 298}.
    {line, [{location, "conformance_lib@sections.erl", 28}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_priv__snapOfSection'}, 1}.
  {label, 299}.
    {call_only, 1, {f, 29}}.

{function, '-isTarget/1-fun-0-', 2, 47}.
  {label, 46}.
    {line, [{location, "conformance_lib@sections.erl", 7}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '-isTarget/1-fun-0-'}, 2}.
  {label, 47}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_eq_exact, {f, 48}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 49}}.
  {label, 48}.
    {move, {atom, false}, {x, 0}}.
  {label, 49}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 52}.
  {label, 51}.
    {line, [{location, "conformance_lib@sections.erl", 8}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_print'}, 1}.
  {label, 52}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 56}.
  {label, 55}.
    {line, [{location, "conformance_lib@sections.erl", 8}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '-bp_show_top-'}, 1}.
  {label, 56}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 54}}.

{function, '-bp_show_elem-', 1, 58}.
  {label, 57}.
    {line, [{location, "conformance_lib@sections.erl", 8}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '-bp_show_elem-'}, 1}.
  {label, 58}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 54}}.

{function, '__bp_show', 2, 54}.
  {label, 53}.
    {line, [{location, "conformance_lib@sections.erl", 8}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_show'}, 2}.
  {label, 54}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 66}, [{x, 0}]}.
    {test, is_eq, {f, 65}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 65}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 66}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 67}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 58}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 67}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 69}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 68}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 68}, [{x, 0}]}.
    {test, is_ne_exact, {f, 68}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 68}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 68}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 73}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 74}}.
  {label, 73}.
    {test, is_eq_exact, {f, 70}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 74}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 54}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 68}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 58}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 69}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 71}, [{x, 0}]}.
    {test, is_ne_exact, {f, 71}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 71}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 72}, [{x, 0}, {atom, undefined}]}.
  {label, 70}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 60}, 2}.
  {label, 71}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 72}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 60}.
  {label, 59}.
    {line, [{location, "conformance_lib@sections.erl", 8}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_tagged'}, 2}.
  {label, 60}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 75}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 75}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 75}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 76}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 62}, 3}.
  {label, 76}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 62}.
  {label, 61}.
    {line, [{location, "conformance_lib@sections.erl", 8}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_render'}, 1}.
  {label, 62}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 77}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 77}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 78}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 78}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 64}.
  {label, 63}.
    {line, [{location, "conformance_lib@sections.erl", 8}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '-bp_render_pair-'}, 1}.
  {label, 64}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 54}}.
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

{function, '-bp_stringify-', 1, 80}.
  {label, 79}.
    {line, [{location, "conformance_lib@sections.erl", 8}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '-bp_stringify-'}, 1}.
  {label, 80}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 81}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 81}.
    {test, is_integer, {f, 82}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 82}.
    {call, 1, {f, 56}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 101}.
  {label, 100}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 101}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 105}}.
  {label, 105}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 107}}.
  {label, 107}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 108}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 4}}.
    {jump, {f, 110}}.
  {label, 108}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 109}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 110}}.
  {label, 109}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 110}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '__bp_tpl_0', 2, 97}.
  {label, 96}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_tpl_0'}, 2}.
  {label, 97}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 101}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 118}.
  {label, 117}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 118}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 120}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 122}, [{x, 0}]}.
    {jump, {f, 123}}.
  {label, 122}.
    {test, is_tuple, {f, 124}, [{x, 0}]}.
    {test, test_arity, {f, 124}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 123}}.
  {label, 124}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 123}.
    {move, {x, 0}, {y, 4}}.
  {label, 125}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 126}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 128}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 128}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 129}}.
  {label, 128}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 129}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 125}}.
  {label, 126}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 127}, [{x, 0}]}.
    {jump, {f, 121}}.
  {label, 127}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 121}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 120}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_1', 2, 114}.
  {label, 113}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_tpl_1'}, 2}.
  {label, 114}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 118}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-bp_at-', 2, 137}.
  {label, 136}.
    {line, [{location, "conformance_lib@sections.erl", 10}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '-bp_at-'}, 2}.
  {label, 137}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 139}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 138}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 139}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 138}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 138}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_2-t/2-fun-0-', 2, 157}.
  {label, 156}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_tpl_2-t/2-fun-0-'}, 2}.
  {label, 157}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 161}, [{x, 0}, {literal, <<"">>}]}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 161}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 164}, [{x, 0}, {atom, nomatch}]}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 164}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 165}, [{x, 0}]}.
    {test, test_arity, {f, 165}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 6}.
  {label, 165}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_2', 2, 153}.
  {label, 152}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_tpl_2'}, 2}.
  {label, 153}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 157}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-parseFile/1-fun-1-', 3, 188}.
  {label, 187}.
    {line, [{location, "conformance_lib@sections.erl", 10}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '-parseFile/1-fun-1-'}, 3}.
  {label, 188}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 189}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 189}.
    {test, is_eq_exact, {f, 190}, [{x, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 191}}.
  {label, 190}.
    {move, {atom, false}, {x, 0}}.
  {label, 191}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 192}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 194}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 194}.
    {test, is_eq_exact, {f, 195}, [{x, 0}, {y, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 196}}.
  {label, 195}.
    {move, {atom, false}, {x, 0}}.
  {label, 196}.
    {jump, {f, 193}}.
  {label, 192}.
    {move, {atom, false}, {x, 0}}.
  {label, 193}.
    {deallocate, 3}.
    return.

{function, '-renderFile/1-fun-2-', 2, 211}.
  {label, 210}.
    {line, [{location, "conformance_lib@sections.erl", 11}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '-renderFile/1-fun-2-'}, 2}.
  {label, 211}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 212}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 212}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 213}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 213}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 214}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 214}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 15}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 80}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-sectionOf/3-fun-3-', 3, 217}.
  {label, 216}.
    {line, [{location, "conformance_lib@sections.erl", 12}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '-sectionOf/3-fun-3-'}, 3}.
  {label, 217}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 219}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 219}.
    {test, is_eq_exact, {f, 220}, [{x, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 221}}.
  {label, 220}.
    {move, {atom, false}, {x, 0}}.
  {label, 221}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 222}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 224}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 224}.
    {test, is_eq_exact, {f, 225}, [{x, 0}, {y, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 226}}.
  {label, 225}.
    {move, {atom, false}, {x, 0}}.
  {label, 226}.
    {jump, {f, 223}}.
  {label, 222}.
    {move, {atom, false}, {x, 0}}.
  {label, 223}.
    {test, is_eq, {f, 218}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_return'}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
  {label, 218}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_3-t/3-fun-0-', 3, 247}.
  {label, 246}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_tpl_3-t/3-fun-0-'}, 3}.
  {label, 247}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 251}}.
  {label, 251}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 253}}.
  {label, 253}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 255}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 254}}.
  {label, 255}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 256}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 254}}.
  {label, 256}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 254}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 258}}.
  {label, 258}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 260}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 259}}.
  {label, 260}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 261}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 259}}.
  {label, 261}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 259}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 263}}.
  {label, 263}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 9}.

{function, '__bp_tpl_3', 3, 243}.
  {label, 242}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_tpl_3'}, 3}.
  {label, 243}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 247}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_4-t/2-fun-0-', 2, 269}.
  {label, 268}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_tpl_4-t/2-fun-0-'}, 2}.
  {label, 269}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 273}}.
  {label, 273}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 275}}.
  {label, 275}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 277}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 276}}.
  {label, 277}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 278}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 276}}.
  {label, 278}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 276}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 280}}.
  {label, 280}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_4', 2, 265}.
  {label, 264}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_tpl_4'}, 2}.
  {label, 265}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 269}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_prim_append', 2, 39}.
  {label, 38}.
    {line, [{location, "conformance_lib@sections.erl", 19}]}.
    {func_info, {atom, conformance_lib@sections}, {atom, '__bp_prim_append'}, 2}.
  {label, 39}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 281}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 281}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
