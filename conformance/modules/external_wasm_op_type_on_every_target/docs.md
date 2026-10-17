# external_wasm_op_type_on_every_target

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> wasm has no host of its own, so `.Wasm` does not name a host symbol
> or carry target text: it is **one cell from a closed vocabulary of four**
> (decisions 238, 440, 481), each a labelled argument holding a value of the
> kind it names, read and checked where the annotation is written — on every
> target, not only on a wasm build: a misspelt opcode, an opcode or an adapter
> whose types differ from the declaration's, or a `fn:` naming no private fn is
> refused on erlang, beam and commonJS too. The arguments are always the
> declared parameters, in order.
