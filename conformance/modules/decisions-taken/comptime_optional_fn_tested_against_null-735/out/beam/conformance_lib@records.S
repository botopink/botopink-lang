{module, conformance_lib@records}.
{exports, [{'HEADER', 0}, {'NEW_SUFFIX', 0}, {parse, 1}, {render, 1}, {matches, 3}, {candidate, 3}, {diff, 2}, {parseBody, 1}, {renderBody, 1}, {'__bp_priv__array_all', 2}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__string_slice', 3}, {'__bp_priv__fail', 2}, {'__bp_priv__lcs', 3}, {'__bp_priv__record', 2}, {'__bp_priv__sameLines', 2}, {'__bp_priv__sameRefusal', 2}, {'__bp_priv__splitLines', 1}, {'__bp_priv__withAt', 2}, {'__bp_priv__withFrame', 2}, {'__bp_priv__withLabel', 2}]}.
{attributes, []}.
{labels, 591}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "conformance_lib@records.erl", 1}]}.
    {func_info, {atom, conformance_lib@records}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 42}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 43}}.
  {label, 42}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 45}}.
  {label, 44}.
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
    {call, 2, {f, 47}}.
  {label, 45}.
  {label, 43}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "conformance_lib@records.erl", 2}]}.
    {func_info, {atom, conformance_lib@records}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 48}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 49}}.
  {label, 48}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 47}}.
    {jump, {f, 51}}.
  {label, 50}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 47}}.
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
    {call, 2, {f, 47}}.
  {label, 51}.
  {label, 49}.
    {deallocate, 6}.
    return.
%%% The records of one case's answer (decisions 457, 475, 485, 789, 868, 989 (5)) — the port of
%%% `conformance/check/src/records.bp`, itself the port of `cell_snap.zig`, plus decision 789's
%%% `build` record. A module's `snapshot/main.snap` (`sections.bp`) holds one run of these records
%%% per case; `parseBody` and `renderBody` read and write that run without the file's header.
%%% 
%%% A run of records is one case's answer on one or every target, a record per line:
%%% 
%%%     botopink-cell 1                 the format and its version, always line 1
%%%     refused <message line>          the compiler refuses the module: its
%%%     at <file>:<line>:<col>            `error…` line, and where (when located)
%%%     label <text>                    the label printed beside the caret (485)
%%%     from <file>:<line>:<col>        one `called from` line of a raise at build,
%%%                                       innermost first (868)
%%%     build <text>                    one line a build body printed (789; `build`
%%%                                       alone for an empty line)
%%%     out <text>                      one line the program printed (`out` alone
%%%                                       for an empty line)
%%%     no-final-newline                the last `out` line ended without `\n`
%%%     abort                           the program exits non-zero
%%%     stderr <text>                   with `abort`: the program's stderr contains
%%%                                       this text
%%% 
%%% The records come in the console's order (decision 904) — `build` lines, then the
%%% refusals (`refused`, `at`, `label`, `from`) or the output, then `abort`, then the
%%% `stderr` claims; nothing prints after a refusal, so a `build` after a `refused` is
%%% malformed — and a
%%% file has exactly one spelling: it parses only when rendering what it parsed
%%% gives back its text. A refusal and an output never share a file. The header
%%% alone is the empty answer.
%%% 
%%% Everything but `stderr` is compared exactly; a `stderr` line is a claim the
%%% abort's stderr contains.
%%% 
%%% Text, not bytes: the program runs on commonJS, where a string is UTF-16. Every
%%% cut here is at an ASCII `\n` or ` `, which no UTF-8 multi-byte sequence holds,
%%% so each piece is the same text `cell_snap.zig` cuts from the file's bytes.
%% The header the records grammar below is written against (a section carries none: the file's
%% line 1 is `sections.HEADER`).

{function, 'HEADER', 0, 7}.
  {label, 6}.
    {line, [{location, "conformance_lib@records.erl", 3}]}.
    {func_info, {atom, conformance_lib@records}, {atom, 'HEADER'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {literal, <<"botopink-cell 1">>}, {x, 0}}.
    {deallocate, 0}.
    return.
%% A candidate's suffix, beside the accepted file it would replace.

{function, 'NEW_SUFFIX', 0, 9}.
  {label, 8}.
    {line, [{location, "conformance_lib@records.erl", 4}]}.
    {func_info, {atom, conformance_lib@records}, {atom, 'NEW_SUFFIX'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<".new">>}, {x, 0}}.
    {deallocate, 0}.
    return.
%% One refusal of a module: the compiler's `error…` line, its location when the
%% diagnostic carries one, the label beside the caret, and the `called from`
%% frames (`from` records; `from` is a reserved word, so the field is `frames`).
%% One module's answer.
%% Why a `.snap` did not parse: its 1-based line and the reason.

{function, fail, 2, 11}.
  {label, 10}.
    {line, [{location, "conformance_lib@records.erl", 6}]}.
    {func_info, {atom, conformance_lib@records}, {atom, fail}, 2}.
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

{function, withAt, 2, 13}.
  {label, 12}.
    {line, [{location, "conformance_lib@records.erl", 7}]}.
    {func_info, {atom, conformance_lib@records}, {atom, withAt}, 2}.
  {label, 13}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 52}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 52}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 53}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 53}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 54}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 54}.
    {test_heap, 6, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Refusal}, {x, 1}, {y, 1}, {x, 2}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, withLabel, 2, 15}.
  {label, 14}.
    {line, [{location, "conformance_lib@records.erl", 8}]}.
    {func_info, {atom, conformance_lib@records}, {atom, withLabel}, 2}.
  {label, 15}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 55}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 55}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 56}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 56}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 57}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 57}.
    {test_heap, 6, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Refusal}, {x, 1}, {x, 2}, {y, 1}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, withFrame, 2, 17}.
  {label, 16}.
    {line, [{location, "conformance_lib@records.erl", 9}]}.
    {func_info, {atom, conformance_lib@records}, {atom, withFrame}, 2}.
  {label, 17}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 58}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 58}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 59}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 59}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 60}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 60}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 61}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 61}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {test_heap, 6, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Refusal}, {y, 2}, {y, 3}, {y, 4}, {x, 0}]}}.
    {deallocate, 7}.
    return.
%% Parse a `.snap`; a malformed one answers its line and the reason.

{function, parse, 1, 19}.
  {label, 18}.
    {line, [{location, "conformance_lib@records.erl", 10}]}.
    {func_info, {atom, conformance_lib@records}, {atom, parse}, 1}.
  {label, 19}.
    {allocate, 49, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}, {y, 35}, {y, 36}, {y, 37}, {y, 38}, {y, 39}, {y, 40}, {y, 41}, {y, 42}, {y, 43}, {y, 44}, {y, 45}, {y, 46}, {y, 47}, {y, 48}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 63}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 64}}.
  {label, 63}.
    {move, {atom, false}, {x, 0}}.
  {label, 64}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 65}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 68}}.
    {test, is_eq, {f, 82}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 82}.
    {move, {atom, true}, {x, 0}}.
  {label, 83}.
    {jump, {f, 66}}.
  {label, 65}.
    {move, {atom, true}, {x, 0}}.
  {label, 66}.
    {test, is_eq, {f, 62}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 85}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"every record ends with a newline">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 62}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 103}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 103}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 104}}.
  {label, 103}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/records.bp:98:43">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 104}.
    {move, {integer, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 102}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 85}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {line, [{location, "conformance_lib@records.erl", 11}]}.
  {label, 105}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 106}, [{y, 9}, {x, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call, 2, {f, 109}}.
    {test, is_ne_exact, {f, 107}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {jump, {f, 112}}.
  {label, 107}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 112}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 9}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 113}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 113}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 114}}.
  {label, 113}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/records.bp:110:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 114}.
    {move, {x, 0}, {y, 9}}.
    {test, is_eq_exact, {f, 115}, [{y, 9}, {integer, 1}]}.
    {call, 0, {f, 7}}.
    {test, is_ne_exact, {f, 116}, [{y, 11}, {x, 0}]}.
    {move, {literal, <<"line 1 must be `botopink-cell 1`">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 116}.
    {jump, {f, 105}}.
  {label, 115}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 11}, {x, 0}}.
    {call, 2, {f, 118}}.
    {move, {x, 0}, {y, 12}}.
    {test, is_lt, {f, 131}, [{y, 12}, {integer, 0}]}.
    {move, {y, 11}, {x, 0}}.
    {jump, {f, 132}}.
  {label, 131}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 12}, {x, 2}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 3, {f, 102}}.
  {label, 132}.
    {move, {x, 0}, {y, 13}}.
    {test, is_ge, {f, 133}, [{y, 12}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 134}}.
  {label, 133}.
    {move, {atom, false}, {x, 0}}.
  {label, 134}.
    {move, {x, 0}, {y, 14}}.
    {test, is_lt, {f, 135}, [{y, 12}, {integer, 0}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 136}}.
  {label, 135}.
    {gc_bif, '+', {f, 0}, 0, [{y, 12}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 137}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 137}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 138}}.
  {label, 137}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/records.bp:119:60">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 138}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {y, 11}, {x, 0}}.
    {call, 3, {f, 102}}.
  {label, 136}.
    {move, {x, 0}, {y, 15}}.
    {test, is_eq, {f, 140}, [{y, 14}, {atom, true}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 142}, [{y, 15}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 143}}.
  {label, 142}.
    {move, {atom, false}, {x, 0}}.
  {label, 143}.
    {jump, {f, 141}}.
  {label, 140}.
    {move, {atom, false}, {x, 0}}.
  {label, 141}.
    {test, is_eq, {f, 139}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"a record's text is never empty (an empty output line is `out` alone)">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 139}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 16}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 144}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 144}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 145}}.
  {label, 144}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/records.bp:123:48">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 145}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 109}}.
    {move, {x, 0}, {y, 17}}.
    {move, {literal, <<"refused">>}, {x, 0}}.
    {test, is_eq_exact, {f, 146}, [{y, 13}, {x, 0}]}.
    {test, is_lt, {f, 148}, [{integer, 1}, {y, 7}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 149}}.
  {label, 148}.
    {move, {atom, false}, {x, 0}}.
  {label, 149}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 150}, [{x, 1}, {atom, true}]}.
    {test, is_ne_exact, {f, 152}, [{y, 7}, {integer, 6}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 153}}.
  {label, 152}.
    {move, {atom, false}, {x, 0}}.
  {label, 153}.
    {jump, {f, 151}}.
  {label, 150}.
    {move, {atom, false}, {x, 0}}.
  {label, 151}.
    {test, is_eq, {f, 147}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`refused` comes before any output">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 147}.
    {move, {integer, 6}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq, {f, 155}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 156}}.
  {label, 155}.
    {move, {atom, true}, {x, 0}}.
  {label, 156}.
    {test, is_eq, {f, 154}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`refused` names the compiler's message">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 154}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 18}}.
    {move, nil, {x, 0}}.
    {test_heap, 6, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Refusal}, {y, 15}, {atom, undefined}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 18}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 157}}.
  {label, 146}.
    {move, {literal, <<"at">>}, {x, 0}}.
    {test, is_eq_exact, {f, 158}, [{y, 13}, {x, 0}]}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq, {f, 160}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 161}}.
  {label, 160}.
    {move, {atom, true}, {x, 0}}.
  {label, 161}.
    {test, is_eq, {f, 159}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`at` names `<file>:<line>:<col>`">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 159}.
    {test, is_ne_exact, {f, 163}, [{y, 7}, {integer, 6}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 164}}.
  {label, 163}.
    {move, {atom, false}, {x, 0}}.
  {label, 164}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 165}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 167}, [{y, 16}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 168}}.
  {label, 167}.
    {move, {atom, false}, {x, 0}}.
  {label, 168}.
    {jump, {f, 166}}.
  {label, 165}.
    {move, {atom, true}, {x, 0}}.
  {label, 166}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 169}, [{x, 1}, {atom, true}]}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq, {f, 171}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 173}}.
  {label, 171}.
    {test, is_tagged_tuple, {f, 172}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 173}}.
  {label, 172}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 173}.
    {test, is_ne_exact, {f, 174}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 175}}.
  {label, 174}.
    {move, {atom, false}, {x, 0}}.
  {label, 175}.
    {jump, {f, 170}}.
  {label, 169}.
    {move, {atom, true}, {x, 0}}.
  {label, 170}.
    {test, is_eq, {f, 162}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`at` follows its `refused` line">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 162}.
    {gc_bif, '-', {f, 0}, 0, [{y, 16}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 176}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 176}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 177}}.
  {label, 176}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/records.bp:137:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 177}.
    {test, is_ne_exact, {f, 178}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 0}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {integer, 0}], {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 179}}.
  {label, 178}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 179}.
    {move, {x, 0}, {y, 19}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_ne_exact, {f, 180}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 21}, {x, 0}}.
    {jump, {f, 181}}.
  {label, 180}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {test_heap, 6, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Refusal}, {x, 1}, {atom, undefined}, {atom, undefined}, {x, 0}]}}.
  {label, 181}.
    {move, {y, 15}, {x, 1}}.
    {call, 2, {f, 13}}.
    {move, {y, 20}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 19}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 182}}.
  {label, 158}.
    {move, {literal, <<"label">>}, {x, 0}}.
    {test, is_eq_exact, {f, 183}, [{y, 13}, {x, 0}]}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq, {f, 185}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 186}}.
  {label, 185}.
    {move, {atom, true}, {x, 0}}.
  {label, 186}.
    {test, is_eq, {f, 184}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`label` names the text printed beside the caret">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 184}.
    {test, is_ne_exact, {f, 188}, [{y, 7}, {integer, 6}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 189}}.
  {label, 188}.
    {move, {atom, false}, {x, 0}}.
  {label, 189}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 190}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 192}, [{y, 16}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 193}}.
  {label, 192}.
    {move, {atom, false}, {x, 0}}.
  {label, 193}.
    {jump, {f, 191}}.
  {label, 190}.
    {move, {atom, true}, {x, 0}}.
  {label, 191}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 194}, [{x, 1}, {atom, true}]}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq, {f, 196}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 198}}.
  {label, 196}.
    {test, is_tagged_tuple, {f, 197}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 198}}.
  {label, 197}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 198}.
    {test, is_eq_exact, {f, 199}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 200}}.
  {label, 199}.
    {move, {atom, false}, {x, 0}}.
  {label, 200}.
    {jump, {f, 195}}.
  {label, 194}.
    {move, {atom, true}, {x, 0}}.
  {label, 195}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 201}, [{x, 1}, {atom, true}]}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq, {f, 203}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 205}}.
  {label, 203}.
    {test, is_tagged_tuple, {f, 204}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
    {jump, {f, 205}}.
  {label, 204}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 205}.
    {test, is_ne_exact, {f, 206}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 207}}.
  {label, 206}.
    {move, {atom, false}, {x, 0}}.
  {label, 207}.
    {jump, {f, 202}}.
  {label, 201}.
    {move, {atom, true}, {x, 0}}.
  {label, 202}.
    {test, is_eq, {f, 187}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`label` follows its `at` line">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 187}.
    {gc_bif, '-', {f, 0}, 0, [{y, 16}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 208}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 208}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 209}}.
  {label, 208}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/records.bp:148:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 209}.
    {test, is_ne_exact, {f, 210}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 0}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {integer, 0}], {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 211}}.
  {label, 210}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 211}.
    {move, {x, 0}, {y, 21}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_ne_exact, {f, 212}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 23}}.
    {move, {y, 23}, {x, 0}}.
    {jump, {f, 213}}.
  {label, 212}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {test_heap, 6, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Refusal}, {x, 1}, {atom, undefined}, {atom, undefined}, {x, 0}]}}.
  {label, 213}.
    {move, {y, 15}, {x, 1}}.
    {call, 2, {f, 15}}.
    {move, {y, 22}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 21}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 214}}.
  {label, 183}.
    {move, {literal, <<"from">>}, {x, 0}}.
    {test, is_eq_exact, {f, 215}, [{y, 13}, {x, 0}]}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq, {f, 217}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 218}}.
  {label, 217}.
    {move, {atom, true}, {x, 0}}.
  {label, 218}.
    {test, is_eq, {f, 216}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`from` names `<file>:<line>:<col>`">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 216}.
    {test, is_ne_exact, {f, 220}, [{y, 7}, {integer, 6}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 221}}.
  {label, 220}.
    {move, {atom, false}, {x, 0}}.
  {label, 221}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 222}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 224}, [{y, 16}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 225}}.
  {label, 224}.
    {move, {atom, false}, {x, 0}}.
  {label, 225}.
    {jump, {f, 223}}.
  {label, 222}.
    {move, {atom, true}, {x, 0}}.
  {label, 223}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 226}, [{x, 1}, {atom, true}]}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq, {f, 228}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 230}}.
  {label, 228}.
    {test, is_tagged_tuple, {f, 229}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 230}}.
  {label, 229}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 230}.
    {test, is_eq_exact, {f, 231}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 232}}.
  {label, 231}.
    {move, {atom, false}, {x, 0}}.
  {label, 232}.
    {jump, {f, 227}}.
  {label, 226}.
    {move, {atom, true}, {x, 0}}.
  {label, 227}.
    {test, is_eq, {f, 219}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`from` follows its `at` line">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 219}.
    {gc_bif, '-', {f, 0}, 0, [{y, 16}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 233}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 233}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 234}}.
  {label, 233}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/records.bp:155:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 234}.
    {test, is_ne_exact, {f, 235}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 0}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {integer, 0}], {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 236}}.
  {label, 235}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 236}.
    {move, {x, 0}, {y, 23}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_ne_exact, {f, 237}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 25}, {x, 0}}.
    {jump, {f, 238}}.
  {label, 237}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {test_heap, 6, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Refusal}, {x, 1}, {atom, undefined}, {atom, undefined}, {x, 0}]}}.
  {label, 238}.
    {move, {y, 15}, {x, 1}}.
    {call, 2, {f, 17}}.
    {move, {y, 24}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 23}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 239}}.
  {label, 215}.
    {move, {literal, <<"build">>}, {x, 0}}.
    {test, is_eq_exact, {f, 240}, [{y, 13}, {x, 0}]}.
    {test, is_eq_exact, {f, 241}, [{y, 7}, {integer, 6}]}.
    {move, {literal, <<"`build` comes before `refused`: nothing prints after a refusal">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 241}.
    {test, is_lt, {f, 242}, [{integer, 1}, {y, 7}]}.
    {move, {literal, <<"`build` comes before `out`, `no-final-newline`, `abort` and `stderr`">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 242}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 15}, {x, 0}}.
    {move, {y, 25}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 243}}.
  {label, 240}.
    {move, {literal, <<"out">>}, {x, 0}}.
    {test, is_eq_exact, {f, 244}, [{y, 13}, {x, 0}]}.
    {test, is_lt, {f, 245}, [{integer, 0}, {y, 16}]}.
    {move, {literal, <<"a refused module prints nothing">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 245}.
    {test, is_lt, {f, 246}, [{integer, 2}, {y, 7}]}.
    {move, {literal, <<"`out` comes before `no-final-newline`, `abort` and `stderr`">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 246}.
    {move, {integer, 2}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 26}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 26}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 26}}.
    {move, {y, 15}, {x, 0}}.
    {move, {y, 26}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 26}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 26}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq, {f, 279}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 280}}.
  {label, 279}.
    {move, {atom, true}, {x, 0}}.
  {label, 280}.
    {move, {x, 0}, {y, 8}}.
    {jump, {f, 281}}.
  {label, 244}.
    {move, {literal, <<"no-final-newline">>}, {x, 0}}.
    {test, is_eq_exact, {f, 282}, [{y, 13}, {x, 0}]}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq, {f, 283}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`no-final-newline` takes no text">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 283}.
    {test, is_ne_exact, {f, 284}, [{y, 7}, {integer, 2}]}.
    {move, {literal, <<"`no-final-newline` follows the last `out` line">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 284}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq, {f, 285}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`no-final-newline` after an empty `out` line has one spelling: drop both">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 285}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 286}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 286}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 287}}.
  {label, 286}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/records.bp:177:52">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 287}.
    {move, {integer, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 4}, {x, 0}}.
    {call, 3, {f, 102}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {jump, {f, 288}}.
  {label, 282}.
    {move, {literal, <<"abort">>}, {x, 0}}.
    {test, is_eq_exact, {f, 289}, [{y, 13}, {x, 0}]}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq, {f, 290}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`abort` takes no text \x{E2}\x{80}\x{94} the exit status is never pinned">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 290}.
    {test, is_lt, {f, 291}, [{integer, 0}, {y, 16}]}.
    {move, {literal, <<"a refused module does not run">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 291}.
    {test, is_lt, {f, 292}, [{integer, 3}, {y, 7}]}.
    {move, {literal, <<"`abort` is written once, after the output">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 292}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {jump, {f, 293}}.
  {label, 289}.
    {move, {literal, <<"stderr">>}, {x, 0}}.
    {test, is_eq_exact, {f, 294}, [{y, 13}, {x, 0}]}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq, {f, 296}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 297}}.
  {label, 296}.
    {move, {atom, true}, {x, 0}}.
  {label, 297}.
    {test, is_eq, {f, 295}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`stderr` names the text the abort's stderr contains">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 295}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq, {f, 299}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 300}}.
  {label, 299}.
    {move, {atom, true}, {x, 0}}.
  {label, 300}.
    {test, is_eq, {f, 298}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`stderr` names an abort: it follows `abort`">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 298}.
    {move, {integer, 5}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 27}}.
    {move, {y, 15}, {x, 0}}.
    {move, {y, 27}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 301}}.
  {label, 294}.
    {move, {literal, <<"unknown record (refused, at, label, from, build, out, no-final-newline, abort, stderr)">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 301}.
  {label, 293}.
  {label, 288}.
  {label, 281}.
  {label, 243}.
  {label, 239}.
  {label, 214}.
  {label, 182}.
  {label, 157}.
    {jump, {f, 105}}.
  {label, 106}.
    {test_heap, 7, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Snap}, {y, 2}, {y, 3}, {y, 4}, {y, 6}, {y, 5}]}}.
    {move, {x, 0}, {y, 28}}.
    {move, {y, 28}, {x, 0}}.
    {call, 1, {f, 23}}.
    {test, is_ne_exact, {f, 302}, [{x, 0}, {y, 0}]}.
    {move, {literal, <<"not the canonical spelling of its records">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 2, {f, 11}, 49}.
  {label, 302}.
    {move, {y, 28}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 49}.
    return.

{function, record, 2, 21}.
  {label, 20}.
    {line, [{location, "conformance_lib@records.erl", 11}]}.
    {func_info, {atom, conformance_lib@records}, {atom, record}, 2}.
  {label, 21}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 303}, [{y, 1}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 304}}.
  {label, 303}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 304}.
    {deallocate, 4}.
    return.
%% The one spelling of `snap`.

{function, render, 1, 23}.
  {label, 22}.
    {line, [{location, "conformance_lib@records.erl", 12}]}.
    {func_info, {atom, conformance_lib@records}, {atom, render}, 1}.
  {label, 23}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
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
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 307}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 307}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 306}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 320}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 320}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 309}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 322}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 322}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 321}, [{x, 1}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 323}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 323}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 68}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq, {f, 324}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 326}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 326}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 327}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 327}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 328}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 328}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 329}}.
  {label, 328}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/records.bp:230:53">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 329}.
    {move, {integer, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 4}, {x, 0}}.
    {call, 3, {f, 102}}.
    {jump, {f, 325}}.
  {label, 324}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 330}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 330}.
  {label, 325}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call, 2, {f, 85}}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 332}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq, {f, 334}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 335}}.
  {label, 334}.
    {move, {atom, true}, {x, 0}}.
  {label, 335}.
    {test, is_eq, {f, 333}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"no-final-newline\n">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 336}}.
  {label, 333}.
  {label, 336}.
    {jump, {f, 337}}.
  {label, 321}.
  {label, 337}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 339}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 339}.
    {test, is_eq, {f, 338}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"abort\n">>}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 340}}.
  {label, 338}.
  {label, 340}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 343}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 343}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 342}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 10}.
    return.

{function, sameLines, 2, 25}.
  {label, 24}.
    {line, [{location, "conformance_lib@records.erl", 13}]}.
    {func_info, {atom, conformance_lib@records}, {atom, sameLines}, 2}.
  {label, 25}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 344}, [{x, 1}, {x, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 344}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "conformance_lib@records.erl", 14}]}.
  {label, 345}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 346}, [{y, 2}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 109}}.
    {test, is_ne_exact, {f, 348}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 349}}.
  {label, 348}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 349}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 109}}.
    {test, is_ne_exact, {f, 350}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 351}}.
  {label, 350}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 351}.
    {test, is_ne_exact, {f, 347}, [{y, 4}, {x, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 347}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 352}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 352}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 353}}.
  {label, 352}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/records.bp:250:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 353}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 345}}.
  {label, 346}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, sameRefusal, 2, 27}.
  {label, 26}.
    {line, [{location, "conformance_lib@records.erl", 14}]}.
    {func_info, {atom, conformance_lib@records}, {atom, sameRefusal}, 2}.
  {label, 27}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 354}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 354}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 355}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 355}.
    {test, is_eq_exact, {f, 356}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 357}}.
  {label, 356}.
    {move, {atom, false}, {x, 0}}.
  {label, 357}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 358}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 360}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 360}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 361}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 361}.
    {test, is_eq_exact, {f, 362}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 363}}.
  {label, 362}.
    {move, {atom, false}, {x, 0}}.
  {label, 363}.
    {jump, {f, 359}}.
  {label, 358}.
    {move, {atom, false}, {x, 0}}.
  {label, 359}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 364}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 366}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 366}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 367}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 367}.
    {test, is_eq_exact, {f, 368}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 369}}.
  {label, 368}.
    {move, {atom, false}, {x, 0}}.
  {label, 369}.
    {jump, {f, 365}}.
  {label, 364}.
    {move, {atom, false}, {x, 0}}.
  {label, 365}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 370}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 372}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 372}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 373}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 373}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 25}}.
    {jump, {f, 371}}.
  {label, 370}.
    {move, {atom, false}, {x, 0}}.
  {label, 371}.
    {deallocate, 4}.
    return.
%% Whether the observed answer is the accepted one: the refusals, the build
%% lines, the output and the abort equal, and every `stderr` claim contained in
%% `observedStderr`.

{function, matches, 3, 29}.
  {label, 28}.
    {line, [{location, "conformance_lib@records.erl", 15}]}.
    {func_info, {atom, conformance_lib@records}, {atom, matches}, 3}.
  {label, 29}.
    {allocate, 8, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 375}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 375}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 376}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 376}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 374}, [{x, 1}, {x, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 374}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "conformance_lib@records.erl", 16}]}.
  {label, 377}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 379}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 379}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 378}, [{y, 3}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 381}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 381}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 109}}.
    {test, is_ne_exact, {f, 380}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 382}}.
  {label, 380}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {test_heap, 6, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Refusal}, {x, 1}, {atom, undefined}, {atom, undefined}, {x, 0}]}}.
  {label, 382}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 384}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 384}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 109}}.
    {test, is_ne_exact, {f, 383}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 385}}.
  {label, 383}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {test_heap, 6, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Refusal}, {x, 1}, {atom, undefined}, {atom, undefined}, {x, 0}]}}.
  {label, 385}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call, 2, {f, 27}}.
    {test, is_eq, {f, 387}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 388}}.
  {label, 387}.
    {move, {atom, true}, {x, 0}}.
  {label, 388}.
    {test, is_eq, {f, 386}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 386}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 389}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 389}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 390}}.
  {label, 389}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/records.bp:272:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 390}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 377}}.
  {label, 378}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 392}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 392}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 393}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 393}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 25}}.
    {test, is_eq, {f, 394}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 395}}.
  {label, 394}.
    {move, {atom, true}, {x, 0}}.
  {label, 395}.
    {test, is_eq, {f, 391}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 391}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 397}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 397}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 398}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 398}.
    {test, is_ne_exact, {f, 396}, [{x, 1}, {x, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 396}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 400}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 400}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 401}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 401}.
    {test, is_ne_exact, {f, 399}, [{x, 1}, {x, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 399}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 404}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 404}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 406}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 403}, 8}.
%% The candidate for an observed answer: what it was, plus the accepted file's
%% `stderr` claims that still hold (a candidate never invents one).

{function, candidate, 3, 31}.
  {label, 30}.
    {line, [{location, "conformance_lib@records.erl", 16}]}.
    {func_info, {atom, conformance_lib@records}, {atom, candidate}, 3}.
  {label, 31}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 410}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 410}.
    {test, is_eq, {f, 409}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_ne_exact, {f, 411}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 412}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 412}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 414}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 417}}.
  {label, 411}.
  {label, 417}.
    {jump, {f, 418}}.
  {label, 409}.
  {label, 418}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 419}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 419}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 420}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 420}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 421}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 421}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 422}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 422}.
    {test_heap, 7, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Snap}, {x, 1}, {x, 2}, {x, 3}, {x, 0}, {y, 3}]}}.
    {deallocate, 5}.
    return.

{function, splitLines, 1, 33}.
  {label, 32}.
    {line, [{location, "conformance_lib@records.erl", 17}]}.
    {func_info, {atom, conformance_lib@records}, {atom, splitLines}, 1}.
  {label, 33}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 423}, [{y, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 423}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 68}}.
    {test, is_eq, {f, 424}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 426}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 426}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 427}}.
  {label, 426}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/records.bp:295:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 427}.
    {move, {integer, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 102}}.
    {jump, {f, 425}}.
  {label, 424}.
    {move, {y, 0}, {x, 0}}.
  {label, 425}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_last, 2, {f, 85}, 5}.
%% A line diff of `before` against `after`: `- ` a line only `before` has, `+ `
%% a line only `after` has, `  ` a line both keep (longest common subsequence).

{function, diff, 2, 35}.
  {label, 34}.
    {line, [{location, "conformance_lib@records.erl", 18}]}.
    {func_info, {atom, conformance_lib@records}, {atom, diff}, 2}.
  {label, 35}.
    {allocate, 36, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}, {y, 35}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 33}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 33}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 428}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 428}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 429}}.
  {label, 428}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/records.bp:307:49">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 429}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {line, [{location, "conformance_lib@records.erl", 19}]}.
  {label, 430}.
    {test, is_lt, {f, 431}, [{integer, 0}, {y, 7}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 7}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 432}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 432}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 433}}.
  {label, 432}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/records.bp:311:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 433}.
    {move, {x, 0}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {line, [{location, "conformance_lib@records.erl", 19}]}.
  {label, 434}.
    {test, is_lt, {f, 435}, [{integer, 0}, {y, 10}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 10}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 436}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 436}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 437}}.
  {label, 436}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/records.bp:315:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 437}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 109}}.
    {test, is_ne_exact, {f, 438}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {jump, {f, 439}}.
  {label, 438}.
    {move, {integer, 0}, {x, 0}}.
  {label, 439}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call, 2, {f, 109}}.
    {test, is_ne_exact, {f, 441}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {jump, {f, 442}}.
  {label, 441}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 442}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call, 2, {f, 109}}.
    {test, is_ne_exact, {f, 443}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {jump, {f, 444}}.
  {label, 443}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 444}.
    {test, is_eq_exact, {f, 440}, [{y, 14}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 10}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 447}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 447}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 448}}.
  {label, 447}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/records.bp:319:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 448}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call, 2, {f, 109}}.
    {test, is_ne_exact, {f, 446}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {jump, {f, 449}}.
  {label, 446}.
    {move, {integer, 0}, {x, 0}}.
  {label, 449}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 450}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 450}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 451}}.
  {label, 450}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/records.bp:319:40">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 451}.
    {jump, {f, 445}}.
  {label, 440}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call, 2, {f, 109}}.
    {test, is_ne_exact, {f, 453}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 17}, {x, 0}}.
    {jump, {f, 454}}.
  {label, 453}.
    {move, {integer, 0}, {x, 0}}.
  {label, 454}.
    {test, is_lt, {f, 452}, [{y, 12}, {x, 0}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call, 2, {f, 109}}.
    {test, is_ne_exact, {f, 456}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 18}, {x, 0}}.
    {jump, {f, 457}}.
  {label, 456}.
    {move, {integer, 0}, {x, 0}}.
  {label, 457}.
    {jump, {f, 455}}.
  {label, 452}.
    {move, {y, 12}, {x, 0}}.
  {label, 455}.
  {label, 445}.
    {move, {x, 0}, {y, 19}}.
    {test_heap, 2, 0}.
    {put_list, {y, 19}, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 434}}.
  {label, 435}.
    {move, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 2, 0}.
    {put_list, {y, 9}, {y, 6}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 430}}.
  {label, 431}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 20}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 21}}.
    {line, [{location, "conformance_lib@records.erl", 19}]}.
  {label, 458}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 460}, [{y, 7}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 461}}.
  {label, 460}.
    {move, {atom, false}, {x, 0}}.
  {label, 461}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 462}, [{x, 1}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 464}, [{y, 21}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 465}}.
  {label, 464}.
    {move, {atom, false}, {x, 0}}.
  {label, 465}.
    {jump, {f, 463}}.
  {label, 462}.
    {move, {atom, true}, {x, 0}}.
  {label, 463}.
    {test, is_eq_exact, {f, 459}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call, 2, {f, 109}}.
    {test, is_ne_exact, {f, 466}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 22}, {x, 0}}.
    {jump, {f, 467}}.
  {label, 466}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 467}.
    {move, {x, 0}, {y, 23}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 21}, {x, 1}}.
    {call, 2, {f, 109}}.
    {test, is_ne_exact, {f, 468}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 24}, {x, 0}}.
    {jump, {f, 469}}.
  {label, 468}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 469}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 471}, [{y, 7}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 472}}.
  {label, 471}.
    {move, {atom, false}, {x, 0}}.
  {label, 472}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 473}, [{x, 1}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 475}, [{y, 21}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 476}}.
  {label, 475}.
    {move, {atom, false}, {x, 0}}.
  {label, 476}.
    {jump, {f, 474}}.
  {label, 473}.
    {move, {atom, false}, {x, 0}}.
  {label, 474}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 477}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 479}, [{y, 23}, {y, 25}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 480}}.
  {label, 479}.
    {move, {atom, false}, {x, 0}}.
  {label, 480}.
    {jump, {f, 478}}.
  {label, 477}.
    {move, {atom, false}, {x, 0}}.
  {label, 478}.
    {test, is_eq, {f, 470}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 26}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 26}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 26}}.
    {move, {y, 23}, {x, 0}}.
    {move, {y, 26}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 26}}.
    {move, {literal, <<"  ">>}, {x, 0}}.
    {move, {y, 26}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 26}}.
    {move, {y, 20}, {x, 0}}.
    {move, {y, 26}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 20}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 7}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 481}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 481}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 482}}.
  {label, 481}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/records.bp:336:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 482}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 21}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 483}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 483}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 484}}.
  {label, 483}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/records.bp:337:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 484}.
    {move, {x, 0}, {y, 21}}.
    {jump, {f, 485}}.
  {label, 470}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 487}, [{y, 7}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 488}}.
  {label, 487}.
    {move, {atom, false}, {x, 0}}.
  {label, 488}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 489}, [{x, 1}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 491}, [{y, 21}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 492}}.
  {label, 491}.
    {move, {atom, false}, {x, 0}}.
  {label, 492}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 493}, [{x, 1}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 7}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 495}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 495}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 496}}.
  {label, 495}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/records.bp:339:46">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 496}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 21}, {x, 2}}.
    {move, {y, 6}, {x, 0}}.
    {call, 3, {f, 37}}.
    {move, {x, 0}, {y, 27}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 21}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 497}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 497}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 498}}.
  {label, 497}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/records.bp:339:72">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 498}.
    {move, {y, 7}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 6}, {x, 0}}.
    {call, 3, {f, 37}}.
    {test, is_ge, {f, 499}, [{y, 27}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 500}}.
  {label, 499}.
    {move, {atom, false}, {x, 0}}.
  {label, 500}.
    {jump, {f, 494}}.
  {label, 493}.
    {move, {atom, true}, {x, 0}}.
  {label, 494}.
    {jump, {f, 490}}.
  {label, 489}.
    {move, {atom, false}, {x, 0}}.
  {label, 490}.
    {test, is_eq, {f, 486}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 28}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 28}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 28}}.
    {move, {y, 23}, {x, 0}}.
    {move, {y, 28}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 28}}.
    {move, {literal, <<"- ">>}, {x, 0}}.
    {move, {y, 28}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 28}}.
    {move, {y, 20}, {x, 0}}.
    {move, {y, 28}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 20}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 7}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 501}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 501}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 502}}.
  {label, 501}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/records.bp:341:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 502}.
    {move, {x, 0}, {y, 7}}.
    {jump, {f, 503}}.
  {label, 486}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 29}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 29}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 29}}.
    {move, {y, 25}, {x, 0}}.
    {move, {y, 29}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 29}}.
    {move, {literal, <<"+ ">>}, {x, 0}}.
    {move, {y, 29}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 29}}.
    {move, {y, 20}, {x, 0}}.
    {move, {y, 29}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 20}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 21}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 504}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 504}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 505}}.
  {label, 504}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/records.bp:344:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 505}.
    {move, {x, 0}, {y, 21}}.
  {label, 503}.
  {label, 485}.
    {jump, {f, 458}}.
  {label, 459}.
    {move, {y, 20}, {x, 0}}.
    {deallocate, 36}.
    return.

{function, lcs, 3, 37}.
  {label, 36}.
    {line, [{location, "conformance_lib@records.erl", 19}]}.
    {func_info, {atom, conformance_lib@records}, {atom, lcs}, 3}.
  {label, 37}.
    {allocate, 7, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 109}}.
    {test, is_ne_exact, {f, 507}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 508}}.
  {label, 507}.
    {move, nil, {x, 0}}.
  {label, 508}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 109}}.
    {test, is_ne_exact, {f, 506}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 509}}.
  {label, 506}.
    {move, {integer, 0}, {x, 0}}.
  {label, 509}.
    {deallocate, 7}.
    return.
%% Parse the records of one section's body (no header; an empty body is the empty answer).
%% A malformed body answers its 1-based line within the body and the reason.

{function, parseBody, 1, 39}.
  {label, 38}.
    {line, [{location, "conformance_lib@records.erl", 20}]}.
    {func_info, {atom, conformance_lib@records}, {atom, parseBody}, 1}.
  {label, 39}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
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
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {call, 1, {f, 19}}.
    {test, is_tagged_tuple, {f, 510}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 511}}.
  {label, 510}.
    {test, is_tagged_tuple, {f, 512}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 513}}.
  {label, 512}.
    {case_end, {x, 0}}.
  {label, 513}.
    {move, {atom, true}, {x, 0}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 516}, [{x, 0}, 3, {atom, conformance_lib@records@@Malformed}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 516}.
    {test, is_lt, {f, 515}, [{integer, 1}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 518}, [{x, 0}, 3, {atom, conformance_lib@records@@Malformed}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 518}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 519}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 519}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 520}}.
  {label, 519}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/records.bp:359:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 520}.
    {jump, {f, 517}}.
  {label, 515}.
    {move, {integer, 1}, {x, 0}}.
  {label, 517}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 521}, [{x, 0}, 3, {atom, conformance_lib@records@@Malformed}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 521}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@records@@Malformed}, {x, 1}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
  {label, 514}.
  {label, 511}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
%% The one spelling of a section's body: `render` without the header line.

{function, renderBody, 1, 41}.
  {label, 40}.
    {line, [{location, "conformance_lib@records.erl", 21}]}.
    {func_info, {atom, conformance_lib@records}, {atom, renderBody}, 1}.
  {label, 41}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
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
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {y, 3}, {x, 0}}.
    {call_last, 3, {f, 102}, 6}.

{function, 'string_slice', 3, 102}.
  {label, 101}.
    {line, [{location, "conformance_lib@records.erl", 22}]}.
    {func_info, {atom, conformance_lib@records}, {atom, 'string_slice'}, 3}.
  {label, 102}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 522}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 524}, 3}.
  {label, 522}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 546}, 3}.

{function, 'array_all', 2, 403}.
  {label, 402}.
    {line, [{location, "conformance_lib@records.erl", 23}]}.
    {func_info, {atom, conformance_lib@records}, {atom, 'array_all'}, 2}.
  {label, 403}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 562}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 563}}.
  {label, 562}.
    {move, {atom, false}, {x, 0}}.
  {label, 563}.
    {deallocate, 2}.
    return.

{function, '__bp_priv__array_all', 2, 566}.
  {label, 565}.
    {line, [{location, "conformance_lib@records.erl", 25}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_priv__array_all'}, 2}.
  {label, 566}.
    {call_only, 2, {f, 403}}.

{function, '__bp_priv__array_range', 2, 568}.
  {label, 567}.
    {line, [{location, "conformance_lib@records.erl", 26}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 568}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 570}.
  {label, 569}.
    {line, [{location, "conformance_lib@records.erl", 27}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 570}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__string_slice', 3, 572}.
  {label, 571}.
    {line, [{location, "conformance_lib@records.erl", 28}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 572}.
    {call_only, 3, {f, 102}}.

{function, '__bp_priv__fail', 2, 574}.
  {label, 573}.
    {line, [{location, "conformance_lib@records.erl", 29}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_priv__fail'}, 2}.
  {label, 574}.
    {call_only, 2, {f, 11}}.

{function, '__bp_priv__lcs', 3, 576}.
  {label, 575}.
    {line, [{location, "conformance_lib@records.erl", 30}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_priv__lcs'}, 3}.
  {label, 576}.
    {call_only, 3, {f, 37}}.

{function, '__bp_priv__record', 2, 578}.
  {label, 577}.
    {line, [{location, "conformance_lib@records.erl", 31}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_priv__record'}, 2}.
  {label, 578}.
    {call_only, 2, {f, 21}}.

{function, '__bp_priv__sameLines', 2, 580}.
  {label, 579}.
    {line, [{location, "conformance_lib@records.erl", 32}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_priv__sameLines'}, 2}.
  {label, 580}.
    {call_only, 2, {f, 25}}.

{function, '__bp_priv__sameRefusal', 2, 582}.
  {label, 581}.
    {line, [{location, "conformance_lib@records.erl", 33}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_priv__sameRefusal'}, 2}.
  {label, 582}.
    {call_only, 2, {f, 27}}.

{function, '__bp_priv__splitLines', 1, 584}.
  {label, 583}.
    {line, [{location, "conformance_lib@records.erl", 34}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_priv__splitLines'}, 1}.
  {label, 584}.
    {call_only, 1, {f, 33}}.

{function, '__bp_priv__withAt', 2, 586}.
  {label, 585}.
    {line, [{location, "conformance_lib@records.erl", 35}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_priv__withAt'}, 2}.
  {label, 586}.
    {call_only, 2, {f, 13}}.

{function, '__bp_priv__withFrame', 2, 588}.
  {label, 587}.
    {line, [{location, "conformance_lib@records.erl", 36}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_priv__withFrame'}, 2}.
  {label, 588}.
    {call_only, 2, {f, 17}}.

{function, '__bp_priv__withLabel', 2, 590}.
  {label, 589}.
    {line, [{location, "conformance_lib@records.erl", 37}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_priv__withLabel'}, 2}.
  {label, 590}.
    {call_only, 2, {f, 15}}.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 72}.
  {label, 71}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 72}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 76}}.
  {label, 76}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 78}}.
  {label, 78}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 79}, [{x, 0}, {atom, true}]}.
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
    {jump, {f, 81}}.
  {label, 79}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 80}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 81}}.
  {label, 80}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 81}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '__bp_tpl_0', 2, 68}.
  {label, 67}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_tpl_0'}, 2}.
  {label, 68}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 72}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 89}.
  {label, 88}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 89}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 91}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 93}, [{x, 0}]}.
    {jump, {f, 94}}.
  {label, 93}.
    {test, is_tuple, {f, 95}, [{x, 0}]}.
    {test, test_arity, {f, 95}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 94}}.
  {label, 95}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 94}.
    {move, {x, 0}, {y, 4}}.
  {label, 96}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 97}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 99}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 99}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 100}}.
  {label, 99}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 100}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 96}}.
  {label, 97}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 98}, [{x, 0}]}.
    {jump, {f, 92}}.
  {label, 98}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 92}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 91}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_1', 2, 85}.
  {label, 84}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_tpl_1'}, 2}.
  {label, 85}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 89}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-bp_at-', 2, 109}.
  {label, 108}.
    {line, [{location, "conformance_lib@records.erl", 11}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '-bp_at-'}, 2}.
  {label, 109}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 111}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 110}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 111}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 110}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 110}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_2-t/2-fun-0-', 2, 122}.
  {label, 121}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_tpl_2-t/2-fun-0-'}, 2}.
  {label, 122}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 126}, [{x, 0}, {literal, <<"">>}]}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 126}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 129}, [{x, 0}, {atom, nomatch}]}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 129}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 130}, [{x, 0}]}.
    {test, test_arity, {f, 130}, [{x, 0}, 2]}.
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
  {label, 130}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_2', 2, 118}.
  {label, 117}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_tpl_2'}, 2}.
  {label, 118}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 122}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_print', 1, 248}.
  {label, 247}.
    {line, [{location, "conformance_lib@records.erl", 11}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_print'}, 1}.
  {label, 248}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 252}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 252}.
  {label, 251}.
    {line, [{location, "conformance_lib@records.erl", 11}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '-bp_show_top-'}, 1}.
  {label, 252}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 250}}.

{function, '-bp_show_elem-', 1, 254}.
  {label, 253}.
    {line, [{location, "conformance_lib@records.erl", 11}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '-bp_show_elem-'}, 1}.
  {label, 254}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 250}}.

{function, '__bp_show', 2, 250}.
  {label, 249}.
    {line, [{location, "conformance_lib@records.erl", 11}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_show'}, 2}.
  {label, 250}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 262}, [{x, 0}]}.
    {test, is_eq, {f, 261}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 261}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 262}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 263}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 254}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 263}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 265}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 264}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 264}, [{x, 0}]}.
    {test, is_ne_exact, {f, 264}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 264}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 264}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 269}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 270}}.
  {label, 269}.
    {test, is_eq_exact, {f, 266}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 270}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 250}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 264}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 254}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 265}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 267}, [{x, 0}]}.
    {test, is_ne_exact, {f, 267}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 267}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 268}, [{x, 0}, {atom, undefined}]}.
  {label, 266}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 256}, 2}.
  {label, 267}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 268}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 256}.
  {label, 255}.
    {line, [{location, "conformance_lib@records.erl", 11}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_tagged'}, 2}.
  {label, 256}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 271}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 271}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 271}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 272}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 258}, 3}.
  {label, 272}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 258}.
  {label, 257}.
    {line, [{location, "conformance_lib@records.erl", 11}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_render'}, 1}.
  {label, 258}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 273}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 273}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 274}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 274}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 260}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 260}.
  {label, 259}.
    {line, [{location, "conformance_lib@records.erl", 11}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '-bp_render_pair-'}, 1}.
  {label, 260}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 250}}.
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

{function, '-bp_stringify-', 1, 276}.
  {label, 275}.
    {line, [{location, "conformance_lib@records.erl", 11}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '-bp_stringify-'}, 1}.
  {label, 276}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 277}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 277}.
    {test, is_integer, {f, 278}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 278}.
    {call, 1, {f, 252}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-render/1-fun-0-', 2, 306}.
  {label, 305}.
    {line, [{location, "conformance_lib@records.erl", 13}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '-render/1-fun-0-'}, 2}.
  {label, 306}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"build">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 21}}.
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
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-render/2-fun-2-', 2, 318}.
  {label, 317}.
    {line, [{location, "conformance_lib@records.erl", 13}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '-render/2-fun-2-'}, 2}.
  {label, 318}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"from ">>}, {x, 0}}.
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
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-render/1-fun-1-', 2, 309}.
  {label, 308}.
    {line, [{location, "conformance_lib@records.erl", 13}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '-render/1-fun-1-'}, 2}.
  {label, 309}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 310}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 310}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"refused ">>}, {x, 0}}.
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
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 312}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 312}.
    {test, is_ne_exact, {f, 311}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"at ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 313}}.
  {label, 311}.
  {label, 313}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 315}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 315}.
    {test, is_ne_exact, {f, 314}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"label ">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 316}}.
  {label, 314}.
  {label, 316}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 319}, [{x, 0}, 5, {atom, conformance_lib@records@@Refusal}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 319}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 318}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '-render/1-fun-3-', 2, 332}.
  {label, 331}.
    {line, [{location, "conformance_lib@records.erl", 13}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '-render/1-fun-3-'}, 2}.
  {label, 332}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"out">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 21}}.
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
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-render/1-fun-4-', 2, 342}.
  {label, 341}.
    {line, [{location, "conformance_lib@records.erl", 13}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '-render/1-fun-4-'}, 2}.
  {label, 342}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"stderr ">>}, {x, 0}}.
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
    {make_fun3, {f, 276}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-matches/3-fun-5-', 2, 406}.
  {label, 405}.
    {line, [{location, "conformance_lib@records.erl", 16}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '-matches/3-fun-5-'}, 2}.
  {label, 406}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 407}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 408}}.
  {label, 407}.
    {move, {atom, true}, {x, 0}}.
  {label, 408}.
    {deallocate, 2}.
    return.

{function, '-candidate/3-fun-6-', 2, 414}.
  {label, 413}.
    {line, [{location, "conformance_lib@records.erl", 17}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '-candidate/3-fun-6-'}, 2}.
  {label, 414}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 415}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 416}}.
  {label, 415}.
    {move, {atom, true}, {x, 0}}.
  {label, 416}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_3-t/3-fun-0-', 3, 528}.
  {label, 527}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_tpl_3-t/3-fun-0-'}, 3}.
  {label, 528}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 532}}.
  {label, 532}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 534}}.
  {label, 534}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 536}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 535}}.
  {label, 536}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 537}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 535}}.
  {label, 537}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 535}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 539}}.
  {label, 539}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 541}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 540}}.
  {label, 541}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 542}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 540}}.
  {label, 542}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 540}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 544}}.
  {label, 544}.
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

{function, '__bp_tpl_3', 3, 524}.
  {label, 523}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_tpl_3'}, 3}.
  {label, 524}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 528}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_4-t/2-fun-0-', 2, 550}.
  {label, 549}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_tpl_4-t/2-fun-0-'}, 2}.
  {label, 550}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 554}}.
  {label, 554}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 556}}.
  {label, 556}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 558}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 557}}.
  {label, 558}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 559}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 557}}.
  {label, 559}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 557}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 561}}.
  {label, 561}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_4', 2, 546}.
  {label, 545}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_tpl_4'}, 2}.
  {label, 546}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 550}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_prim_append', 2, 47}.
  {label, 46}.
    {line, [{location, "conformance_lib@records.erl", 24}]}.
    {func_info, {atom, conformance_lib@records}, {atom, '__bp_prim_append'}, 2}.
  {label, 47}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 564}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 564}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
