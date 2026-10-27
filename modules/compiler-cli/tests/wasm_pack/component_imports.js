// wasm_pack.sh's structural reader (decisions 1036, 1079 (2)): a component
// binary's top-level imports, and whether each unit's bytes are embedded in it.
//
//   node component_imports.js <component.wasm> [<unit.wasm>…]
//
// Prints `import <name>` for each top-level import of the component, in order,
// then `missing <unit>` for each unit file whose bytes do not occur in it.
// Exit 2 when the file is not a component binary or its import section does
// not read; otherwise 0 (the caller judges the lines).
"use strict";
const fs = require("fs");

const [file, ...units] = process.argv.slice(2);
const b = fs.readFileSync(file);
const die = (why) => { console.error(`component_imports: ${file}: ${why}`); process.exit(2); };

if (b.length < 8 || b.readUInt32BE(0) !== 0x0061736d || b[4] !== 0x0d || b[6] !== 0x01) die("not a component binary");

let i = 8;
const u32 = () => {
  let r = 0, s = 0;
  for (;;) {
    if (i >= b.length) die("a LEB128 runs past the end");
    const x = b[i++];
    r += (x & 0x7f) * 2 ** s;
    if (!(x & 0x80)) return r;
    s += 7;
  }
};
const str = () => { const n = u32(); const t = b.subarray(i, i + n).toString("utf8"); i += n; return t; };

const names = [];
while (i < b.length) {
  const id = b[i++];
  const size = u32();
  const end = i + size;
  if (end > b.length) die("a section runs past the end");
  if (id === 10) {
    // import section: vec(importname' externdesc)
    const n = u32();
    for (let k = 0; k < n; k++) {
      const tag = b[i++];
      if (tag !== 0x00 && tag !== 0x01) die(`import name tag 0x${tag.toString(16)}`);
      const name = str();
      if (tag === 0x01) { if (b[i++] === 0x01) str(); } // a version suffix
      names.push(name);
      const kind = b[i++];
      if (kind === 0x00) { i++; u32(); }                       // core module: 0x11 typeidx
      else if (kind === 0x01 || kind === 0x04 || kind === 0x05) u32(); // func, component, instance
      else if (kind === 0x03) { if (b[i++] === 0x00) u32(); }  // type: eq idx | sub resource
      else if (kind === 0x02) { if (b[i++] === 0x00) u32(); else { const v = b[i]; if (v >= 0x73) i++; else u32(); } }
      else die(`import ${name}: extern kind 0x${kind.toString(16)}`);
    }
    if (i !== end) die("the import section does not read to its end");
  }
  i = end;
}
for (const n of names) console.log(`import ${n}`);
for (const u of units) if (b.indexOf(fs.readFileSync(u)) < 0) console.log(`missing ${u}`);
