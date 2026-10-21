# beam_memory_annotations

The reference text this cell shows (from `conformance/docs.md`, § `compiler.beamMemory` — where a module var lives on the BEAM):

> `#[compiler.beamMemory(.<member>)]` above a module `var` names its memory on erlang and
> beam. The member is one of a closed enum: `Ets`, the default, which a bare `var`
> already means, and `PersistentTerm`; any other value is refused at the annotation
> (decision 547). Every part is checked at `botopink check`, in a project whose target
> is erlang or beam:
