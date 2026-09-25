// smoke.js — the browser build answers like the native compiler, under node.
//
//   node modules/compiler-web/tests/smoke.js zig-out/web/botopink.wasm
//
// Loads glue.js the way a page would, compiles one program to the four
// targets, and pins the three answers the build must give: generated text
// for a program that compiles, a rendered diagnostic for one that does not,
// and — until front 18 step 5's comptime half reaches the page's engine — the
// located refusal for a program with a decorator or a template.
// Every assertion is hard; the process exits 1 on the first failure.
"use strict";
const fs = require("fs");
const path = require("path");
const { Compiler, run, wasmBytes } = require(path.join(__dirname, "..", "glue.js"));

const wasmPath = process.argv[2];
if (!wasmPath) {
  console.error("usage: node smoke.js <botopink.wasm>");
  process.exit(2);
}

function assert(cond, what) {
  if (!cond) {
    console.error(`smoke: FAIL ${what}`);
    process.exit(1);
  }
  console.log(`smoke: ok  ${what}`);
}

const PLAIN = `
fn greet(name: string): string {
  "hello, " + name
}

fn main() {
  print(greet("web"))
}
`;

const RUNNABLE = `fn greet(name: string) -> string {
    return "hello, " + name;
}

fn main() {
    @print(greet("web"));
}
`;

const BROKEN = `
fn main() {
  val x = 
}
`;

const COMPTIME = `
pub fn shout(comptime q: @Expr<string>) -> @Expr<string> {
    return q.build("\\"" + q.text().toUpper() + "\\"");
}

pub fn describe(comptime decl: @Decl) {
    @emit("pub fn describe" + decl.name + "() -> string { return \\"" + decl.name + "\\"; }");
}

#[describe]
type User(name: string)

val s = shout "browser";

fn main() {
    @print(s);
    @print(describeUser());
}
`;

(async () => {
  const compiler = await Compiler.load(fs.readFileSync(wasmPath));

  for (const target of ["commonJS", "erlang", "beam", "wasm"]) {
    compiler.reset();
    compiler.addSource("main", PLAIN);
    const out = compiler.compile(target);
    assert(out.status === 0, `${target}: a plain program compiles (status 0)`);
    assert(out.target === target && out.modules.length === 1, `${target}: one module answered`);
    const m = out.modules[0];
    assert(m.name === "main" && m.diagnostic === null, `${target}: no diagnostic`);
    assert(m.code.length > 0 && m.code.includes("hello, "), `${target}: the generated text carries the program`);
  }

  // The `wasm` target's binary runs in the page: the same program, printed.
  compiler.reset();
  compiler.addSource("main", RUNNABLE);
  const w = compiler.compile("wasm");
  assert(w.status === 0 && typeof w.modules[0].wasm === "string", "wasm: the binary module is answered beside the text");
  const ran = run(wasmBytes(w.modules[0].wasm));
  assert(ran.trap === null && ran.stdout === "hello, web\n", `wasm: the binary runs and prints the program's output (got ${JSON.stringify(ran)})`);
  const js = compiler.compile("commonJS");
  assert(js.modules[0].wasm === null, "commonJS: no binary module");

  compiler.reset();
  compiler.addSource("main", BROKEN);
  const broken = compiler.compile("commonJS");
  assert(broken.status === 1, "a program that does not parse answers status 1");
  assert(typeof broken.modules[0].diagnostic === "string" && broken.modules[0].diagnostic.includes("main.bp:"), "the diagnostic is rendered and located");
  assert(broken.modules[0].code === "", "a failed module has no artifact");

  compiler.reset();
  compiler.addSource("main", COMPTIME);
  const ct = compiler.compile("commonJS");
  assert(ct.status === 1, "a program with a template is refused on a host with no comptime runtime");
  assert(String(ct.modules[0].diagnostic).includes("runtime") && String(ct.modules[0].diagnostic).includes("in this build of the compiler"), "the refusal names the missing runtime");

  let threw = false;
  try {
    compiler.compile("typescript");
  } catch (err) {
    threw = /unknown target/.test(err.message);
  }
  assert(threw, "an unknown target throws, it does not answer");

  assert(compiler.stdout === "", "the compiler wrote nothing to stdout");

  // The page never talks to `Compiler` directly: it posts messages to glue.js
  // running as a Worker. Node has no worker scope of that shape, so one is
  // emulated — `WorkerGlobalScope` defined, `self` an instance of it — and
  // glue.js is loaded again as the Worker would load it.
  const replies = [];
  class WorkerGlobalScope {}
  const scope = new WorkerGlobalScope();
  scope.postMessage = (m) => replies.push(m);
  global.WorkerGlobalScope = WorkerGlobalScope;
  global.self = scope;
  delete require.cache[require.resolve(path.join(__dirname, "..", "glue.js"))];
  require(path.join(__dirname, "..", "glue.js"));
  assert(typeof scope.onmessage === "function", "loaded as a Worker, glue.js installs the message handler");
  await scope.onmessage({ data: { id: 1, op: "load", wasm: fs.readFileSync(wasmPath) } });
  assert(replies.length === 1 && replies[0].id === 1 && replies[0].ok === true, "the Worker answers `load`");
  await scope.onmessage({ data: { id: 2, op: "compile", target: "wasm", sources: [{ path: "main", source: PLAIN }] } });
  const r = replies[1];
  assert(r.ok === true && r.status === 0 && r.result.modules[0].code.includes("(module"), "the Worker answers `compile` with the generated text");
  assert(typeof r.ms === "number" && r.ms >= 0, "the Worker reports the compile time");
  await scope.onmessage({ data: { id: 4, op: "run", wasm: w.modules[0].wasm } });
  assert(replies[2].ok === true && replies[2].run.trap === null && replies[2].run.stdout === "hello, web\n", "the Worker answers `run` with the program's output");
  await scope.onmessage({ data: { id: 3, op: "compile", target: "nope", sources: [] } });
  assert(replies[3].ok === false && /unknown target/.test(replies[3].error), "a failed request comes back as `ok: false` with the error");

  // The demo page loads two resources and nothing else after that: every
  // `src`/`href`/`fetch`/URL in index.html names glue.js or botopink.wasm.
  const html = fs.readFileSync(path.join(__dirname, "..", "index.html"), "utf8");
  const refs = [...html.matchAll(/(?:src|href)=["']([^"']+)["']|new Worker\(["']([^"']+)["']\)|wasm: ["']([^"']+)["']|https?:\/\/[^\s"'<)]+/g)]
    .map((m) => m[1] || m[2] || m[3] || m[0]);
  const outside = refs.filter((r) => r !== "glue.js" && r !== "botopink.wasm");
  assert(outside.length === 0, `index.html references only glue.js and botopink.wasm${outside.length ? ` (found ${outside.join(", ")})` : ""}`);

  console.log("smoke: all green");
})().catch((err) => {
  console.error(`smoke: FAIL ${err.stack || err}`);
  process.exit(1);
});
