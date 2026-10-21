# Decision 198 — A `.bpp` file is another spelling of a `.bp` module, unfolded by the toolchain onto a library's default function.

A `.bpp` file is another spelling of a `.bp` module. [draft/components/Card.bpp](draft/components/Card.bpp) has a
header — ordinary botopink, its declarations first (`type Props`, `fn twice`) and its statements after
(`val size`, which reads `props`) — then the separator `---` and the markup. The toolchain unfolds it onto the default
function of the package the manifest's `"bpp"` key names, found by `#[bpp.html]`: here
[draft/comptime/markup.bp](draft/comptime/markup.bp), a template that answers the markup's text. The header's
declarations become the module's, its statements the start of the module's anonymous `pub default fn (..props:
Props)`, and the markup the literal handed to `markup`, so a diagnostic inside it lands on the `.bpp` line. `main`
imports the default by the file's name, `components.Card`, passes the props by label, and prints
`<h1>{props.title}</h1>`. The manifest that names the package in `"bpp"` is written when the draft is promoted; a
phase-1 draft carries none.

Cells that also bear on it: `modules/bpp/cells/bpp_unfold_props`, `modules/bpp/cells/bpp_roles_found`, `modules/bpp/cells/bpp_beside_bp`,
`modules/decisions-taken/bpp_declaration_after_statement_refused-552/cells/bpp_declaration_after_statement`, `modules/bpp/cells/bpp_diagnostics_located`.

[draft/main.bp](draft/main.bp)
