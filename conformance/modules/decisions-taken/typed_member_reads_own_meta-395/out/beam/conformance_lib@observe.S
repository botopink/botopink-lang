{module, conformance_lib@observe}.
{exports, [{refusalOf, 7}, {refusedAnswer, 3}, {ranAnswer, 5}, {linesOf, 1}, {reds, 3}, {assemble, 3}, {'__bp_priv__array_any', 2}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__string_slice', 3}, {'__bp_priv__appended', 2}, {'__bp_priv__candidateBody', 3}, {'__bp_priv__kept', 4}, {'__bp_priv__observedOf', 2}]}.
{attributes, []}.
{labels, 239}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "conformance_lib@observe.erl", 1}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, 'array_range'}, 2}.
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
    {line, [{location, "conformance_lib@observe.erl", 2}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, 'array_repeat'}, 2}.
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
%%% What one case answered, as data, and the reading of a whole module's answers against its
%%% `snapshot/main.snap` (decision 989 (5), (9)).
%% One case's observed answer: its records and, for an abort, the text its stderr held.
%% A refused load's diagnostic as the `refused` / `at` / `label` / `from` records of 475, 485, 532:
%% the whole `error…` line as `botopink build` prints it — `error[<code>]: ` when the diagnostic
%% carries a code its message does not already start with, `error: ` otherwise —, its location when it
%% points somewhere, the label beside the caret, the `called from` frames innermost first.

{function, refusalOf, 7, 7}.
  {label, 6}.
    {line, [{location, "conformance_lib@observe.erl", 3}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, refusalOf}, 7}.
  {label, 7}.
    {allocate, 17, 7}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {x, 4}, {y, 4}}.
    {move, {x, 5}, {y, 5}}.
    {move, {x, 6}, {y, 6}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 37}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 38}}.
  {label, 37}.
    {move, {atom, false}, {x, 0}}.
  {label, 38}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 39}, [{x, 1}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<":">>}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 70}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 73}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 74}}.
  {label, 73}.
    {move, {atom, true}, {x, 0}}.
  {label, 74}.
    {jump, {f, 40}}.
  {label, 39}.
    {move, {atom, true}, {x, 0}}.
  {label, 40}.
    {test, is_eq, {f, 36}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"error: ">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 70}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 75}}.
  {label, 36}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, <<"]: ">>}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, <<"error[">>}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 70}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 75}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 76}, [{y, 2}, {x, 0}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 77}}.
  {label, 76}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, <<":">>}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, <<":">>}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 70}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 77}.
    {move, {x, 0}, {y, 12}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Refusal}, {y, 10}, {y, 12}, {y, 5}, {y, 6}]}}.
    {deallocate, 17}.
    return.
%% The answer of a case whose load refused: the build lines first (decision 904), then the refusals.

{function, refusedAnswer, 3, 9}.
  {label, 8}.
    {line, [{location, "conformance_lib@observe.erl", 4}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, refusedAnswer}, 3}.
  {label, 9}.
    {allocate, 11, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 7, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Snap}, {y, 2}, {x, 1}, {x, 2}, {x, 3}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@observe@@Observed}, {y, 0}, {x, 1}, {x, 0}]}}.
    {deallocate, 11}.
    return.
%% The answer of a case that ran: the build lines, then what it printed, `abort` when the run failed.

{function, ranAnswer, 5, 11}.
  {label, 10}.
    {line, [{location, "conformance_lib@observe.erl", 5}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, ranAnswer}, 5}.
  {label, 11}.
    {allocate, 13, 5}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {x, 4}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {x, 0}, {y, 6}}.
    {move, nil, {x, 0}}.
    {test_heap, 7, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Snap}, {y, 5}, {y, 6}, {y, 2}, {y, 3}, {x, 0}]}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@observe@@Observed}, {y, 0}, {x, 0}, {y, 4}]}}.
    {deallocate, 13}.
    return.
%% A build text's lines, each without its newline (`""` has none).

{function, linesOf, 1, 13}.
  {label, 12}.
    {line, [{location, "conformance_lib@observe.erl", 6}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, linesOf}, 1}.
  {label, 13}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 78}, [{y, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 78}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 81}}.
    {test, is_eq, {f, 79}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 98}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 98}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 99}}.
  {label, 98}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/observe.bp:41:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 99}.
    {move, {integer, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 97}}.
    {jump, {f, 95}}.
  {label, 79}.
    {move, {y, 0}, {x, 0}}.
  {label, 95}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_last, 2, {f, 101}, 5}.
%% The cases whose observed answer on `target` is not the accepted one, in module order.

{function, reds, 3, 15}.
  {label, 14}.
    {line, [{location, "conformance_lib@observe.erl", 7}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, reds}, 3}.
  {label, 15}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 118}, 0, 0, {x, 0}, {list, [{y, 0}, {y, 2}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, observedOf, 2, 17}.
  {label, 16}.
    {line, [{location, "conformance_lib@observe.erl", 8}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, observedOf}, 2}.
  {label, 17}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 128}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {'try', {y, 2}, {f, 131}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {try_end, {y, 2}}.
    {jump, {f, 134}}.
  {label, 131}.
    {try_case, {y, 2}}.
    {test, is_eq_exact, {f, 133}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 132}, [{x, 1}, 2, {atom, '__bp_try'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 132}.
    {test, is_tagged_tuple, {f, 133}, [{x, 1}, 2, {atom, '__bp_return'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 133}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 134}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, candidateBody, 3, 19}.
  {label, 18}.
    {line, [{location, "conformance_lib@observe.erl", 9}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, candidateBody}, 3}.
  {label, 19}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 135}, [{x, 0}, 4, {atom, conformance_lib@observe@@Observed}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 135}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, conformance_lib@sections, find, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_ne_exact, {f, 136}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 139}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 139}.
    {call_ext, 1, {extfunc, conformance_lib@records, parseBody, 1}}.
    {test, is_tagged_tuple, {f, 137}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 138}}.
  {label, 137}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 138}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 140}}.
  {label, 136}.
  {label, 140}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 141}, [{x, 0}, 4, {atom, conformance_lib@observe@@Observed}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 141}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 142}, [{x, 0}, 4, {atom, conformance_lib@observe@@Observed}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 142}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 3, {extfunc, conformance_lib@records, candidate, 3}}.
    {call_ext_last, 1, {extfunc, conformance_lib@records, renderBody, 1}, 6}.

{function, kept, 4, 21}.
  {label, 20}.
    {line, [{location, "conformance_lib@observe.erl", 10}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, kept}, 4}.
  {label, 21}.
    {allocate, 13, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 143}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 143}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 17}}.
    {move, {x, 0}, {y, 4}}.
    {test, is_eq_exact, {f, 144}, [{y, 4}, {atom, undefined}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 144}.
    {move, {y, 4}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 145}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 145}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, conformance_lib@sections, answeringTarget, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 146}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 146}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 147}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 147}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, conformance_lib@sections, headerOf, 2}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 70}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 149}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 149}.
    {test, is_eq_exact, {f, 150}, [{x, 0}, {y, 6}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 151}}.
  {label, 150}.
    {move, {atom, false}, {x, 0}}.
  {label, 151}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 152}, [{x, 1}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 154}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 154}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 155}, [{x, 0}, 4, {atom, conformance_lib@observe@@Observed}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 155}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 156}, [{x, 0}, 4, {atom, conformance_lib@observe@@Observed}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 156}.
    {move, {x, 2}, {x, 3}}.
    {move, {x, 0}, {x, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {call_ext, 5, {extfunc, conformance_lib@sections, same, 5}}.
    {test, is_eq, {f, 157}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 158}}.
  {label, 157}.
    {move, {atom, true}, {x, 0}}.
  {label, 158}.
    {jump, {f, 153}}.
  {label, 152}.
    {move, {atom, false}, {x, 0}}.
  {label, 153}.
    {test, is_eq, {f, 148}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 3, {f, 19}}.
    {move, {y, 9}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 70}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 13}.
    return.
  {label, 148}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 159}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 159}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 70}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 13}.
    return.

{function, appended, 2, 23}.
  {label, 22}.
    {line, [{location, "conformance_lib@observe.erl", 11}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, appended}, 2}.
  {label, 23}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 163}, [{x, 0}, 2, {atom, conformance_lib@sections@@SnapFile}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 163}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 165}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 162}}.
    {test, is_eq, {f, 160}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 160}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 170}, [{x, 0}, 4, {atom, conformance_lib@observe@@Observed}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 170}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 171}, [{x, 0}, 4, {atom, conformance_lib@observe@@Observed}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 171}.
    {move, {x, 0}, {x, 2}}.
    {move, {atom, undefined}, {x, 0}}.
    {call_ext, 3, {extfunc, conformance_lib@records, candidate, 3}}.
    {call_ext, 1, {extfunc, conformance_lib@records, renderBody, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 172}, [{x, 0}, 4, {atom, conformance_lib@observe@@Observed}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 172}.
    {move, {atom, undefined}, {x, 1}}.
    {call_ext, 2, {extfunc, conformance_lib@sections, headerOf, 2}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 70}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 3}.
    return.
%% The module's whole candidate file for a run on `target`: the file's sections in its order, every
%% unchanged section byte for byte; a case whose answer differs gets the candidate in the section it
%% answered on `target` (its departure there, else its plain section); a case the file does not
%% have is appended as a plain section; a section of a case the module no longer has is dropped.

{function, assemble, 3, 25}.
  {label, 24}.
    {line, [{location, "conformance_lib@observe.erl", 12}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, assemble}, 3}.
  {label, 25}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 173}, [{x, 0}, 2, {atom, conformance_lib@sections@@SnapFile}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 173}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 3}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 175}, 0, 0, {x, 0}, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 177}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call, 2, {f, 179}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call, 2, {f, 179}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"botopink-cell 2\n">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 70}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 6}.
    return.

{function, 'string_slice', 3, 97}.
  {label, 96}.
    {line, [{location, "conformance_lib@observe.erl", 13}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, 'string_slice'}, 3}.
  {label, 97}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 180}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 182}, 3}.
  {label, 180}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 204}, 3}.

{function, 'array_any', 2, 162}.
  {label, 161}.
    {line, [{location, "conformance_lib@observe.erl", 14}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, 'array_any'}, 2}.
  {label, 162}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 220}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 221}}.
  {label, 220}.
    {move, {atom, false}, {x, 0}}.
  {label, 221}.
    {deallocate, 2}.
    return.

{function, '__bp_priv__array_any', 2, 224}.
  {label, 223}.
    {line, [{location, "conformance_lib@observe.erl", 16}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_priv__array_any'}, 2}.
  {label, 224}.
    {call_only, 2, {f, 162}}.

{function, '__bp_priv__array_range', 2, 226}.
  {label, 225}.
    {line, [{location, "conformance_lib@observe.erl", 17}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 226}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 228}.
  {label, 227}.
    {line, [{location, "conformance_lib@observe.erl", 18}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 228}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__string_slice', 3, 230}.
  {label, 229}.
    {line, [{location, "conformance_lib@observe.erl", 19}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 230}.
    {call_only, 3, {f, 97}}.

{function, '__bp_priv__appended', 2, 232}.
  {label, 231}.
    {line, [{location, "conformance_lib@observe.erl", 20}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_priv__appended'}, 2}.
  {label, 232}.
    {call_only, 2, {f, 23}}.

{function, '__bp_priv__candidateBody', 3, 234}.
  {label, 233}.
    {line, [{location, "conformance_lib@observe.erl", 21}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_priv__candidateBody'}, 3}.
  {label, 234}.
    {call_only, 3, {f, 19}}.

{function, '__bp_priv__kept', 4, 236}.
  {label, 235}.
    {line, [{location, "conformance_lib@observe.erl", 22}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_priv__kept'}, 4}.
  {label, 236}.
    {call_only, 4, {f, 21}}.

{function, '__bp_priv__observedOf', 2, 238}.
  {label, 237}.
    {line, [{location, "conformance_lib@observe.erl", 23}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_priv__observedOf'}, 2}.
  {label, 238}.
    {call_only, 2, {f, 17}}.

{function, '__bp_print', 1, 42}.
  {label, 41}.
    {line, [{location, "conformance_lib@observe.erl", 4}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_print'}, 1}.
  {label, 42}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 46}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 46}.
  {label, 45}.
    {line, [{location, "conformance_lib@observe.erl", 4}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '-bp_show_top-'}, 1}.
  {label, 46}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 44}}.

{function, '-bp_show_elem-', 1, 48}.
  {label, 47}.
    {line, [{location, "conformance_lib@observe.erl", 4}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '-bp_show_elem-'}, 1}.
  {label, 48}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 44}}.

{function, '__bp_show', 2, 44}.
  {label, 43}.
    {line, [{location, "conformance_lib@observe.erl", 4}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_show'}, 2}.
  {label, 44}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 56}, [{x, 0}]}.
    {test, is_eq, {f, 55}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 55}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 56}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 57}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 48}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 57}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 59}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 58}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 58}, [{x, 0}]}.
    {test, is_ne_exact, {f, 58}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 58}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 58}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 63}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 64}}.
  {label, 63}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 64}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 44}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 58}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 48}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 59}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 61}, [{x, 0}]}.
    {test, is_ne_exact, {f, 61}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 61}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 62}, [{x, 0}, {atom, undefined}]}.
  {label, 60}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 50}, 2}.
  {label, 61}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 62}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 50}.
  {label, 49}.
    {line, [{location, "conformance_lib@observe.erl", 4}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_tagged'}, 2}.
  {label, 50}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 65}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 65}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 65}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 66}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 52}, 3}.
  {label, 66}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 52}.
  {label, 51}.
    {line, [{location, "conformance_lib@observe.erl", 4}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_render'}, 1}.
  {label, 52}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 67}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 67}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 68}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 54}.
  {label, 53}.
    {line, [{location, "conformance_lib@observe.erl", 4}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '-bp_render_pair-'}, 1}.
  {label, 54}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 44}}.
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

{function, '-bp_stringify-', 1, 70}.
  {label, 69}.
    {line, [{location, "conformance_lib@observe.erl", 4}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '-bp_stringify-'}, 1}.
  {label, 70}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 71}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 71}.
    {test, is_integer, {f, 72}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 72}.
    {call, 1, {f, 46}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 85}.
  {label, 84}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 85}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 89}}.
  {label, 89}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 91}}.
  {label, 91}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 92}, [{x, 0}, {atom, true}]}.
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
    {jump, {f, 94}}.
  {label, 92}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 93}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 94}}.
  {label, 93}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 94}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '__bp_tpl_0', 2, 81}.
  {label, 80}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_tpl_0'}, 2}.
  {label, 81}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 85}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 105}.
  {label, 104}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 105}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 107}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 109}, [{x, 0}]}.
    {jump, {f, 110}}.
  {label, 109}.
    {test, is_tuple, {f, 111}, [{x, 0}]}.
    {test, test_arity, {f, 111}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 110}}.
  {label, 111}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 110}.
    {move, {x, 0}, {y, 4}}.
  {label, 112}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 113}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 115}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 115}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 116}}.
  {label, 115}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 116}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 112}}.
  {label, 113}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 114}, [{x, 0}]}.
    {jump, {f, 108}}.
  {label, 114}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 108}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 107}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_1', 2, 101}.
  {label, 100}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_tpl_1'}, 2}.
  {label, 101}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 105}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-reds/3-fun-0-', 4, 118}.
  {label, 117}.
    {line, [{location, "conformance_lib@observe.erl", 8}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '-reds/3-fun-0-'}, 4}.
  {label, 118}.
    {allocate, 4, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 120}, [{x, 0}, 4, {atom, conformance_lib@observe@@Observed}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 120}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 121}, [{x, 0}, 4, {atom, conformance_lib@observe@@Observed}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 121}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 122}, [{x, 0}, 4, {atom, conformance_lib@observe@@Observed}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 122}.
    {move, {x, 2}, {x, 3}}.
    {move, {x, 0}, {x, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {call_ext, 5, {extfunc, conformance_lib@sections, same, 5}}.
    {test, is_eq, {f, 123}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 124}}.
  {label, 123}.
    {move, {atom, true}, {x, 0}}.
  {label, 124}.
    {test, is_eq, {f, 119}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 125}, [{x, 0}, 4, {atom, conformance_lib@observe@@Observed}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 125}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 126}}.
  {label, 119}.
  {label, 126}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '-observedOf/2-fun-1-', 2, 128}.
  {label, 127}.
    {line, [{location, "conformance_lib@observe.erl", 9}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '-observedOf/2-fun-1-'}, 2}.
  {label, 128}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 130}, [{x, 0}, 4, {atom, conformance_lib@observe@@Observed}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 130}.
    {test, is_eq_exact, {f, 129}, [{x, 0}, {y, 1}]}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_return'}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
  {label, 129}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-appended/2-fun-2-', 2, 165}.
  {label, 164}.
    {line, [{location, "conformance_lib@observe.erl", 12}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '-appended/2-fun-2-'}, 2}.
  {label, 165}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 166}, [{x, 0}, 4, {atom, conformance_lib@sections@@Section}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 166}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 167}, [{x, 0}, 4, {atom, conformance_lib@observe@@Observed}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 167}.
    {test, is_eq_exact, {f, 168}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 169}}.
  {label, 168}.
    {move, {atom, false}, {x, 0}}.
  {label, 169}.
    {deallocate, 2}.
    return.

{function, '-assemble/3-fun-3-', 4, 175}.
  {label, 174}.
    {line, [{location, "conformance_lib@observe.erl", 13}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '-assemble/3-fun-3-'}, 4}.
  {label, 175}.
    {allocate, 4, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 3}}.
    {move, {y, 3}, {x, 2}}.
    {move, {y, 2}, {x, 1}}.
    {call, 4, {f, 21}}.
    {deallocate, 4}.
    return.

{function, '-assemble/3-fun-4-', 2, 177}.
  {label, 176}.
    {line, [{location, "conformance_lib@observe.erl", 13}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '-assemble/3-fun-4-'}, 2}.
  {label, 177}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 23}}.
    {deallocate, 2}.
    return.

{function, '-bp_join-', 2, 179}.
  {label, 178}.
    {line, [{location, "conformance_lib@observe.erl", 13}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '-bp_join-'}, 2}.
  {label, 179}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 70}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '__bp_tpl_2-t/3-fun-0-', 3, 186}.
  {label, 185}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_tpl_2-t/3-fun-0-'}, 3}.
  {label, 186}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 190}}.
  {label, 190}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 192}}.
  {label, 192}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 194}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 193}}.
  {label, 194}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 195}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 193}}.
  {label, 195}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 193}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 197}}.
  {label, 197}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 199}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 198}}.
  {label, 199}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 200}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 198}}.
  {label, 200}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 198}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 202}}.
  {label, 202}.
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

{function, '__bp_tpl_2', 3, 182}.
  {label, 181}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_tpl_2'}, 3}.
  {label, 182}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 186}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_3-t/2-fun-0-', 2, 208}.
  {label, 207}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_tpl_3-t/2-fun-0-'}, 2}.
  {label, 208}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 212}}.
  {label, 212}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 214}}.
  {label, 214}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 216}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 215}}.
  {label, 216}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 217}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 215}}.
  {label, 217}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 215}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 219}}.
  {label, 219}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_3', 2, 204}.
  {label, 203}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_tpl_3'}, 2}.
  {label, 204}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 208}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_prim_append', 2, 31}.
  {label, 30}.
    {line, [{location, "conformance_lib@observe.erl", 15}]}.
    {func_info, {atom, conformance_lib@observe}, {atom, '__bp_prim_append'}, 2}.
  {label, 31}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 222}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 222}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
