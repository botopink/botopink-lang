# template_lookup_decl_write

The reference text this cell shows (from `conformance/docs.md`, § Template functions):

> **A declaration looked up** (decision 415). In a template body a name of the
> literal is text, not a name of the template's module: `q.lookup(name)` — `name`
> a word of the literal — resolves it where the call stands and answers the
> declaration as a read-only `?@Decl`: `name` (an import's alias answers the
> declaration it names), `kind`, `module`, `fields`, `variants`, `methods`,
> `params`; `null` when nothing of that name is in scope. `q.bindings()` lists
> every declaration a word of the literal names. `setMeta`, `addMeta`,
> `addMember`, `addType` and `wrapWith` on the handle are refused at the call
> (`template-lookup-decl-write`).
