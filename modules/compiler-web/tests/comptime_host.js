// comptime_host.js — evaluations through the page's comptime host, under node.
//
//   node modules/compiler-web/tests/comptime_host.js <plan> [<repeat>]
//
// `<plan>` is the file `codegen/wat/comptime_page.zig` `plan` wrote. It is
// placed in a memory as the compiler's memory holds it and run through
// `bp_host.run_units` / `result_*` / `printed_*` (`glue.js` `hostServed`),
// `<repeat>` times (default 1) in one host — each evaluation on fresh
// instances. Prints one JSON array of `{ status, text, printed }` on stdout.
// Driven by the zig test `modules/compiler-core/src/codegen/tests/
// comptime_page_host.zig`, which turns each answer into the native host's
// `Answer` (`comptime_page.finish`) and compares it with the native host's.
"use strict";
const fs = require("fs");
const path = require("path");
const { hostServed } = require(path.join(__dirname, "..", "glue.js"));

const planPath = process.argv[2];
if (!planPath) {
  console.error("usage: node comptime_host.js <plan> [<repeat>]");
  process.exit(2);
}
const repeat = Number(process.argv[3] || "1");
const plan = new Uint8Array(fs.readFileSync(planPath));
const decoder = new TextDecoder();

const memory = new WebAssembly.Memory({ initial: Math.ceil((plan.length + 65536) / 65536) });
const state = { memory };
const planPtr = 8;
new Uint8Array(memory.buffer, planPtr, plan.length).set(plan);

const host = hostServed(state);
const out = [];
for (let i = 0; i < repeat; i++) {
  const status = host.run_units(planPtr, plan.length);
  const take = (len, copy) => {
    const n = len();
    const need = planPtr + plan.length + n;
    if (need > memory.buffer.byteLength) memory.grow(Math.ceil((need - memory.buffer.byteLength) / 65536));
    const at = planPtr + plan.length;
    copy(at);
    return decoder.decode(new Uint8Array(memory.buffer, at, n));
  };
  out.push({ status, text: take(host.result_len, host.result_copy), printed: take(host.printed_len, host.printed_copy) });
}
process.stdout.write(JSON.stringify(out));
