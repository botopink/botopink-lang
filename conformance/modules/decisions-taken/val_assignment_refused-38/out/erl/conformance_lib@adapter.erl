-module(conformance_lib@adapter).
-export([target/0, frames/1, buildOutput/1, ranOf/1]).

%%% The language features decision 989 builds in parallel, in one place: each function below is the

%%% one spot a landing of its piece changes, and until then it refuses by name (never a silent stub).

%%% See `../docs.md` for which function waits on what.

%% import os, Diagnostic, Module, RunFailure

%% The target the program runs on: `commonJS`, `erlang`, `beam` or `wasm` (989 (7), piece 3:

%% `io.os.target()`, never readable at comptime).

target() ->
    std@io@os:target().

%% The `called from` frames of a refusal, innermost first (989 (4), piece 4: `Diagnostic.from`).

frames(D) ->
    erlang:element(8, D).

%% What the loaded package's build bodies printed, before its refusals (decision 904; 989 (4),

%% piece 4: `Module.buildOutput()`).

buildOutput(M) ->
    std@compiler@@Module:buildOutput(M).

%% What a run printed, and why it failed (989 (1), piece 2: `Module.run()` answers

%% `Result<string, RunFailure>`). `m.run()` is written in the `compiler.init` body itself

%% (`run-outside-init`), so the adapter takes its answer: `Ok(text)` is the printed text, `Error(f)`

%% the text printed before the failure (`f.output`) and its message.

%% type Ran: printed, failed, failure

ranOf(R) ->
    case R of
        {ok, Text} ->
            {conformance_lib@adapter@@Ran, Text, false, <<"">>};
        {error, F} ->
            {conformance_lib@adapter@@Ran, erlang:element(4, F), true, erlang:element(3, F)}
    end.
