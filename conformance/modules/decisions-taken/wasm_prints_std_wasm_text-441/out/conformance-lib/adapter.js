const { Module: __bp_enum_Module } = require("../std/compiler.js");

//// The language features decision 989 builds in parallel, in one place: each function below is the

//// one spot a landing of its piece changes, and until then it refuses by name (never a silent stub).

//// See `../docs.md` for which function waits on what.

const os = require("../std/io/os.js");
const { Diagnostic, Module, RunFailure } = require("../std/compiler.js");

/** The target the program runs on: `commonJS`, `erlang`, `beam` or `wasm` (989 (7), piece 3: */

/** `io.os.target()`, never readable at comptime). */

function target() {
    return os.target();
}
exports.target = target;

/** The `called from` frames of a refusal, innermost first (989 (4), piece 4: `Diagnostic.from`). */

function frames(d) {
    return d["`from`"];
}
exports.frames = frames;

/** What the loaded package's build bodies printed, before its refusals (decision 904; 989 (4), */

/** piece 4: `Module.buildOutput()`). */

function buildOutput(m) {
    return __bp_enum_Module.prototype.buildOutput.call(m);
}
exports.buildOutput = buildOutput;

/** What a run printed, and why it failed (989 (1), piece 2: `Module.run()` answers */

/** `Result<string, RunFailure>`). `m.run()` is written in the `compiler.init` body itself */

/** (`run-outside-init`), so the adapter takes its answer: `Ok(text)` is the printed text, `Error(f)` */

/** the text printed before the failure (`f.output`) and its message. */

class Ran {
    constructor(printed, failed, failure) {
        this.printed = printed;
        this.failed = failed;
        this.failure = failure;
    }
}
Ran.prototype.__bp = "Ran";
exports.Ran = Ran;

function ranOf(r) {
    return (() => {
        const _s = r;
        if ("ok" in _s) {
            const text = _s.ok;
            return new Ran(text, false, "");
        }
        if ("error" in _s) {
            const f = _s.error;
            return new Ran(f.output, true, f.message);
        }
        throw new Error("case_clause");
    })();
}
exports.ranOf = ranOf;

Object.defineProperty(exports, "__bp_priv__", { value: { __bp_enum_Module, os, Diagnostic, Module, RunFailure, target, frames, buildOutput, Ran, ranOf } });
