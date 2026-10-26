{module, std@io@stdin}.
{exports, [{isTTY, 0}, {readLine, 0}, {readChunk, 0}]}.
{attributes, []}.
{labels, 128}.
%%% std/io/stdin — the process's standard input, cross-backend (decision 506 (1)).
%%% 
%%% Reference:
%%%   Node.js  — https://nodejs.org/api/process.html#processstdin
%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/io.html#get_line/2
%%% 
%%% `readLine()` is the next line of input without its terminator (`\n` or `\r\n`), a last
%%% line with no terminator included, and `null` at the end of input — the same on commonJS,
%%% erlang and beam. It is a `Async` so that a program waiting on a terminal is not blocked
%%% as a whole on Node: the line arrives through the stream's own events, so a signal handler
%%% (`io.process.onSignal`) still runs while a prompt waits. Erlang is eager and blocks the
%%% calling process in `io:get_line/2`.
%%% 
%%% `readChunk()` is the byte-level companion (what `io.terminal.keys` reads): the input
%%% that has arrived, however long, `null` at the end of input. A program mixes the two
%%% freely; what `readLine` has not taken is what `readChunk` answers.
%%% 
%%% There is no wasm binding: a call is refused at the call (`std-unsupported-on-target`,
%%% decision 518 (4)).
% Does standard input read from a terminal? `false` for a pipe, a file or `/dev/null`.
% Node: `tty.isatty(0)`. Erlang: `prim_tty:isatty(stdin)`.

{function, isTTY, 0, 9}.
  {label, 8}.
    {line, [{location, "std@io@stdin.erl", 1}]}.
    {func_info, {atom, std@io@stdin}, {atom, isTTY}, 0}.
  {label, 9}.
    {call_only, 0, {f, 7}}.
% Node's shared reader: the buffer, the queue of readers and the pump that answers them in
% order, created on first use and kept on `globalThis` (the stream is the process's, so is the
% buffer). The stream is paused whenever nobody waits, so a process whose reads are done can
% exit. Erlang keeps no state: `io:get_line/2` and `io:get_chars/3` are the buffer.
% The next line of input without its line terminator, `null` at the end of input.

%% @Async — eager lowering
{function, readLine, 0, 3}.
  {label, 2}.
    {line, [{location, "std@io@stdin.erl", 2}]}.
    {func_info, {atom, std@io@stdin}, {atom, readLine}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {call, 0, {f, 41}}.
    {call, 1, {f, 11}}.
    {deallocate, 0}.
    return.
% What has arrived on standard input — one piece, never empty — or `null` at the end of input.
% On a terminal in raw mode (`io.terminal.setRaw`) that is the key just pressed, an escape
% sequence whole. Erlang reads a character at a time: after an Escape it waits 50 ms for the rest
% of the sequence, so a lone Escape key is told from the start of an arrow key there as well.

%% @Async — eager lowering
{function, readChunk, 0, 5}.
  {label, 4}.
    {line, [{location, "std@io@stdin.erl", 3}]}.
    {func_info, {atom, std@io@stdin}, {atom, readChunk}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {call, 0, {f, 41}}.
    {call, 1, {f, 43}}.
    {deallocate, 0}.
    return.
% ── tests ────────────────────────────────────────────────────────────────────
% A test cannot give itself an input: `readLine` / `readChunk` answer the end of input in the
% conformance cell `std_io_stdin_eof`.

{function, '__bp_tpl_0', 0, 7}.
  {label, 6}.
    {func_info, {atom, std@io@stdin}, {atom, '__bp_tpl_0'}, 0}.
  {label, 7}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {atom, stdin}, {x, 0}}.
    {call_ext, 1, {extfunc, prim_tty, isatty, 1}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, true}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_1-t/1-fun-0-', 1, 15}.
  {label, 14}.
    {func_info, {atom, std@io@stdin}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 1}.
  {label, 15}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [binary, {encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 19}}.
  {label, 19}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {atom, ''}, {x, 1}}.
    {call_ext, 2, {extfunc, io, get_line, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 21}, [{x, 0}, {atom, eof}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 21}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 22}, [{x, 0}]}.
    {test, test_arity, {f, 22}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 22}, [{x, 0}, {atom, error}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 22}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 25}}.
  {label, 25}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 26}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, binary, last, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 4}}.
    {jump, {f, 28}}.
  {label, 26}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 27}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 28}}.
  {label, 27}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 28}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 32}}.
  {label, 32}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 33}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, at, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 13}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 5}}.
    {jump, {f, 35}}.
  {label, 33}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 34}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 5}}.
    {jump, {f, 35}}.
  {label, 34}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 35}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 37}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_ext_last, 3, {extfunc, binary, part, 3}, 8}.
  {label, 37}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_ext_last, 3, {extfunc, binary, part, 3}, 8}.
  {label, 38}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 30}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 39}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_1', 1, 11}.
  {label, 10}.
    {func_info, {atom, std@io@stdin}, {atom, '__bp_tpl_1'}, 1}.
  {label, 11}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_2', 0, 41}.
  {label, 40}.
    {func_info, {atom, std@io@stdin}, {atom, '__bp_tpl_2'}, 0}.
  {label, 41}.
    {allocate, 0, 0}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_tpl_3---t/1-fun-0--fun-1--fun-2-', 2, 63}.
  {label, 62}.
    {func_info, {atom, std@io@stdin}, {atom, '__bp_tpl_3---t/1-fun-0--fun-1--fun-2-'}, 2}.
  {label, 63}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {atom, ''}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, io, get_chars, 3}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    send.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_3--t/1-fun-0--fun-1-', 1, 55}.
  {label, 54}.
    {func_info, {atom, std@io@stdin}, {atom, '__bp_tpl_3--t/1-fun-0--fun-1-'}, 1}.
  {label, 55}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, bp_stdin_pend}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 59}, [{x, 0}, {atom, undefined}]}.
    {call_ext, 0, {extfunc, erlang, make_ref, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 61}}.
  {label, 61}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 63}, 0, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, spawn, 1}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 67}}.
  {label, 67}.
    {move, {atom, bp_stdin_pend}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 4}.
  {label, 59}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_3--t/1-fun-0--fun-3-', 2, 72}.
  {label, 71}.
    {func_info, {atom, std@io@stdin}, {atom, '__bp_tpl_3--t/1-fun-0--fun-3-'}, 2}.
  {label, 72}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 4}}.
    {move, {atom, bp_stdin_pend}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 76}}.
  {label, 76}.
  {label, 77}.
    {loop_rec, {f, 78}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 81}, [{x, 0}]}.
    {test, test_arity, {f, 81}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test, is_eq_exact, {f, 81}, [{x, 0}, {x, 1}]}.
    {move, {y, 6}, {y, 2}}.
    remove_message.
    {move, {atom, bp_stdin_pend}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 81}.
    {move, nil, {y, 4}}.
    {move, nil, {y, 2}}.
    {move, nil, {y, 5}}.
    {move, nil, {y, 6}}.
    {move, nil, {y, 7}}.
    {loop_rec_end, {f, 77}}.
  {label, 78}.
    {wait_timeout, {f, 77}, {y, 3}}.
    timeout.
    {move, {atom, timeout}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_tpl_3--t/1-fun-0--fun-4-', 1, 85}.
  {label, 84}.
    {func_info, {atom, std@io@stdin}, {atom, '__bp_tpl_3--t/1-fun-0--fun-4-'}, 1}.
  {label, 85}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 89}}.
  {label, 89}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, at, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 91}}.
  {label, 91}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 93}, [{x, 0}, {literal, {2, 79}}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 93}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 94}, [{x, 0}, {literal, {2, 91}}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 94}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 95}, [{x, 0}]}.
    {test, test_arity, {f, 95}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 95}, [{x, 0}, {integer, 79}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 95}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 96}, [{x, 0}]}.
    {test, test_arity, {f, 96}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 96}, [{x, 0}, {integer, 91}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, binary, last, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 98}}.
  {label, 98}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 64}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 99}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 126}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 5}}.
    {jump, {f, 101}}.
  {label, 99}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 100}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 5}}.
    {jump, {f, 101}}.
  {label, 100}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 101}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 96}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_tpl_3--t/1-fun-0--fun-5-', 3, 106}.
  {label, 105}.
    {func_info, {atom, std@io@stdin}, {atom, '__bp_tpl_3--t/1-fun-0--fun-5-'}, 3}.
  {label, 106}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 106}, 1, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 50}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_binary, {f, 110}, [{x, 0}]}.
    {jump, {f, 111}}.
  {label, 111}.
    {move, {y, 3}, {x, 0}}.
    {test, is_binary, {f, 112}, [{x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {test, is_binary, {f, 112}, [{x, 0}]}.
    {test_heap, 4, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {put_list, {y, 3}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 113}}.
  {label, 112}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 113}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 2}}.
    {jump, {f, 115}}.
  {label, 115}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 117}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 117}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 118}, [{x, 0}, {atom, false}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_last, 3, {f, 106}, 6}.
  {label, 118}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 110}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '__bp_tpl_3-t/1-fun-0-', 1, 47}.
  {label, 46}.
    {func_info, {atom, std@io@stdin}, {atom, '__bp_tpl_3-t/1-fun-0-'}, 1}.
  {label, 47}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [binary, {encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 51}}.
  {label, 51}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 53}}.
  {label, 53}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 55}, 2, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 70}}.
  {label, 70}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 72}, 3, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 83}}.
  {label, 83}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 85}, 4, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 104}}.
  {label, 104}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 106}, 1, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 121}}.
  {label, 121}.
    {move, {atom, infinity}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 123}, [{x, 0}]}.
    {jump, {f, 124}}.
  {label, 124}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, <<"\x{1B}">>}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 126}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 5}.
    return.
  {label, 126}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 127}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 127}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 123}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_3', 1, 43}.
  {label, 42}.
    {func_info, {atom, std@io@stdin}, {atom, '__bp_tpl_3'}, 1}.
  {label, 43}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 47}, 5, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.
