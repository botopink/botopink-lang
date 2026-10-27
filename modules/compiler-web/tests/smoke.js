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
const { Compiler, run, programUnits, wasmBytes } = require(path.join(__dirname, "..", "glue.js"));

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
import {io.terminal.print} from "std";
fn greet(name: string) -> string {
  "hello, " + name
}

fn main() -> void {
  print(greet("web"))
}
`;

const RUNNABLE = `import {io.terminal.print} from "std";
fn greet(name: string) -> string {
    return "hello, " + name;
}

fn main() -> void {
    print(greet("web"));
}
`;

const BROKEN = `
fn main() -> void {
  val x = 
}
`;

const COMPTIME = `
import {compiler} from "std";
import {io.terminal.print} from "std";

pub fn shout(syntax q: string) -> string {
    return compiler.build("\\"" + compiler.text(q).toUpper() + "\\"");
}

pub fn describe(syntax decl: unknown) -> void {
    @emit("pub fn describe" + compiler.name(decl)! + "() -> string { return \\"" + compiler.name(decl)! + "\\"; }");
}

#[describe]
type User(name: string)

val s = shout @\`browser\`;

fn main() -> void {
    print(s);
    print(describeUser());
}
`;

// What the native compiler records for COMPTIME (the wasm comptime runtime,
// whatever the target — decision 434).
const NATIVE_TEMPLATE_REPLY = `----- COMPTIME REPLY -- template shout
\`\`\`json
{
  "kind": "code",
  "source": "\\"BROWSER\\""
}
\`\`\``;
const NATIVE_DECORATOR_REPLY = `----- COMPTIME REPLY -- decorator describe
\`\`\`json
{
  "contributions": [
    {
      "kind": "emit",
      "source": "pub fn describeUser() -> string { return \\"User\\"; }"
    }
  ],
  "kind": "ok"
}
\`\`\``;

(async () => {
  const compiler = await Compiler.load(fs.readFileSync(wasmPath));

  // Decision 109: an erlang/beam module atom starts with the project's package
  // name. Without one — no `botopink.json` — the compile is refused, located.
  compiler.reset();
  compiler.addSource("main", PLAIN);
  const nameless = compiler.compile("erlang");
  assert(nameless.status === 1 && String(nameless.modules[0].diagnostic).includes("belongs to no package"), "erlang: a project with no package name is refused, not given a fallback name");
  compiler.setPackage("web");

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
  // Decision 1069 (5): the page composes the runtime core, the std units the
  // program reaches and its own module, in order, through one linking path.
  assert(Array.isArray(w.runtime) && w.runtime.length > 0 && w.runtime[0].name === "std@__rt", "wasm: the runtime core is answered beside the program, first");
  const ran = run(programUnits(w, "main"));
  assert(ran.trap === null && ran.stdout === "hello, web\n", `wasm: the binary runs and prints the program's output (got ${JSON.stringify(ran)})`);
  const js = compiler.compile("commonJS");
  assert(js.modules[0].wasm === null, "commonJS: no binary module");

  compiler.reset();
  compiler.addSource("main", BROKEN);
  const broken = compiler.compile("commonJS");
  assert(broken.status === 1, "a program that does not parse answers status 1");
  assert(typeof broken.modules[0].diagnostic === "string" && broken.modules[0].diagnostic.includes("main.bp:"), "the diagnostic is rendered and located");
  assert(broken.modules[0].code === "", "a failed module has no artifact");

  // Decision 519: the page's compiler is handed no reader — `@embed` is a
  // located refusal, never a read.
  compiler.reset();
  compiler.addSource("main", 'import {io.terminal.print} from "std";\npub fn main() -> void {\n    print(@embed("assets/logo.png").size);\n}\n');
  const embed = compiler.compile("commonJS");
  assert(embed.status === 1 && String(embed.modules[0].diagnostic).includes("embed-no-reader") && String(embed.modules[0].diagnostic).includes("main.bp:3:11"), `@embed is refused in the page, located (${embed.modules[0].diagnostic})`);

  // The decorator + template program: on every target its comptime runs on
  // the wasm runtime (decision 434) — lowered by the compiler, run by the
  // page's engine through `bp_host` — and answers what the native compiler
  // answers.
  for (const target of ["commonJS", "wasm", "erlang", "beam"]) {
    compiler.reset();
    compiler.addSource("main", COMPTIME);
    const ct = compiler.compile(target);
    assert(ct.status === 0, `${target}: the decorator + template program compiles in the page (${ct.modules[0].diagnostic || ""})`);
    const trace = ct.modules[0].comptimeTrace || "";
    assert(trace.includes(NATIVE_TEMPLATE_REPLY), `${target}: the template's COMPTIME REPLY equals the native one`);
    assert(trace.includes(NATIVE_DECORATOR_REPLY), `${target}: the decorator's COMPTIME REPLY equals the native one`);
    assert(ct.modules[0].code.includes("BROWSER"), `${target}: the expansion is in the generated code`);
  }

  // Decision 1026's cell `wasm_std_unit_per_module` in the browser column
  // (1069 (5)): the CLI test's own projects (`modules/compiler-cli/tests/
  // wasm_std_unit_per_module/`) compiled in the page and composed by `run`.
  const cell = path.join(__dirname, "..", "..", "compiler-cli", "tests", "wasm_std_unit_per_module");
  const cellProgram = (name) => {
    compiler.reset();
    compiler.setPackage(JSON.parse(fs.readFileSync(path.join(cell, name, "botopink.json"), "utf8")).name);
    compiler.addSource("main", fs.readFileSync(path.join(cell, name, "src", "main.bp"), "utf8"));
    const out = compiler.compile("wasm");
    assert(out.status === 0, `wasm_std_unit_per_module/${name}: compiles in the page (${out.modules[0].diagnostic || ""})`);
    return out;
  };
  // `hello` composes the runtime core alone and answers what the CLI's run answers.
  const hello = cellProgram("hello");
  assert(hello.runtime.map((u) => u.name).join(" ") === "std@__rt", `wasm_std_unit_per_module/hello: the page composes std@__rt and no std unit (got ${hello.runtime.map((u) => u.name).join(" ")})`);
  const helloRan = run(programUnits(hello, "main"));
  assert(helloRan.trap === null && helloRan.stdout === "hello, world\n", `wasm_std_unit_per_module/hello: runs in the page (got ${JSON.stringify(helloRan)})`);
  // `files` reaches `std@io@fs`: each std unit composed after the units it
  // imports, the core first; the page serves no file system (334 (1)), so its
  // `bp_fs` imports are refused by name before a byte runs.
  const files = cellProgram("files");
  const names = files.runtime.map((u) => u.name);
  assert(names[0] === "std@__rt" && names.includes("std@io@fs"), `wasm_std_unit_per_module/files: the page composes std@__rt first and std@io@fs (got ${names.join(" ")})`);
  for (const [i, u] of files.runtime.entries()) {
    const deps = new Set(WebAssembly.Module.imports(new WebAssembly.Module(wasmBytes(u.wasm))).map((imp) => imp.module).filter((m) => m.startsWith("std@")));
    for (const d of deps) assert(names.indexOf(d) >= 0 && names.indexOf(d) < i, `wasm_std_unit_per_module/files: ${u.name} is composed after ${d}, which it imports`);
  }
  let refusedFs = null;
  try {
    run(programUnits(files, "main"));
  } catch (err) {
    refusedFs = err.message;
  }
  assert(refusedFs !== null && /imports bp_fs\.[a-z_]+, which the page does not serve/.test(refusedFs), `wasm_std_unit_per_module/files: the page refuses the file system by name (${refusedFs})`);

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
  await scope.onmessage({ data: { id: 2, op: "compile", target: "wasm", package: "web", sources: [{ path: "main", source: PLAIN }] } });
  const r = replies[1];
  assert(r.ok === true && r.status === 0 && r.result.modules[0].code.includes("(module"), "the Worker answers `compile` with the generated text");
  assert(typeof r.ms === "number" && r.ms >= 0, "the Worker reports the compile time");
  await scope.onmessage({ data: { id: 4, op: "run", wasm: w.modules[0].wasm, runtime: w.runtime } });
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
