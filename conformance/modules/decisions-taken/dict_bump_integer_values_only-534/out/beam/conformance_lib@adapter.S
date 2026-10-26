{module, conformance_lib@adapter}.
{exports, [{target, 0}, {frames, 1}, {buildOutput, 1}, {ranOf, 1}]}.
{attributes, []}.
{labels, 16}.
%%% The language features decision 989 builds in parallel, in one place: each function below is the
%%% one spot a landing of its piece changes, and until then it refuses by name (never a silent stub).
%%% See `../docs.md` for which function waits on what.
%% The target the program runs on: `commonJS`, `erlang`, `beam` or `wasm` (989 (7), piece 3:
%% `io.os.target()`, never readable at comptime).

{function, target, 0, 3}.
  {label, 2}.
    {line, [{location, "conformance_lib@adapter.erl", 1}]}.
    {func_info, {atom, conformance_lib@adapter}, {atom, target}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {call_ext_last, 0, {extfunc, std@io@os, target, 0}, 0}.
%% The `called from` frames of a refusal, innermost first (989 (4), piece 4: `Diagnostic.from`).

{function, frames, 1, 5}.
  {label, 4}.
    {line, [{location, "conformance_lib@adapter.erl", 2}]}.
    {func_info, {atom, conformance_lib@adapter}, {atom, frames}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 10}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 7, {x, 0}}.
  {label, 10}.
    {deallocate, 1}.
    return.
%% What the loaded package's build bodies printed, before its refusals (decision 904; 989 (4),
%% piece 4: `Module.buildOutput()`).

{function, buildOutput, 1, 7}.
  {label, 6}.
    {line, [{location, "conformance_lib@adapter.erl", 3}]}.
    {func_info, {atom, conformance_lib@adapter}, {atom, buildOutput}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, std@compiler@@Module, buildOutput, 1}, 1}.
%% What a run printed, and why it failed (989 (1), piece 2: `Module.run()` answers
%% `Result<string, RunFailure>`). `m.run()` is written in the `compiler.init` body itself
%% (`run-outside-init`), so the adapter takes its answer: `Ok(text)` is the printed text, `Error(f)`
%% the text printed before the failure (`f.output`) and its message.

{function, ranOf, 1, 9}.
  {label, 8}.
    {line, [{location, "conformance_lib@adapter.erl", 4}]}.
    {func_info, {atom, conformance_lib@adapter}, {atom, ranOf}, 1}.
  {label, 9}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 12}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@adapter@@Ran}, {y, 1}, {x, 1}, {x, 0}]}}.
    {jump, {f, 11}}.
  {label, 12}.
    {test, is_tagged_tuple, {f, 13}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 14}, [{x, 0}, 4, {atom, std@compiler@@RunFailure}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 14}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 15}, [{x, 0}, 4, {atom, std@compiler@@RunFailure}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 15}.
    {test_heap, 5, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, conformance_lib@adapter@@Ran}, {x, 1}, {x, 2}, {x, 0}]}}.
    {jump, {f, 11}}.
  {label, 13}.
    {case_end, {x, 0}}.
  {label, 11}.
    {deallocate, 3}.
    return.
