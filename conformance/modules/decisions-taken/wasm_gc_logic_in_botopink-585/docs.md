# Decision 585 — s3 P2: logic in botopink, a leaf only for the atom botopink cannot write, and what the prelude already has is named, never duplicated.

On the WasmGC target the runtime's logic is written in botopink, a hand-written leaf only for the atom botopink cannot
write, and what the prelude already has is named, never duplicated. The program touches each piece the decision lists.
`slice`, `append` and `unique` lower the `default fn` bodies `primitives.bp` holds — no `.wat` cell of their own. The
seeded random keeps its state in a mutable global the codegen declares and the leaf names, so seeding `7` twice
replays the same two draws and the line prints `true`. The byte codecs are botopink bodies over three leaves —
`bytes.length`, `bytes.at`, `bytes.ofWords` — and `hi!` encodes to `686921` and `aGkh`. `hash.contentHash` is a
botopink body too, folding code points, so `🎉` hashes as `djb2([127881])` on every target. Each line is the same on
wasm as on commonJS, erlang and beam.

[draft/main.bp](draft/main.bp)
