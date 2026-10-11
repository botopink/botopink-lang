# beam_memory_annotations

The reference text this cell shows (from `conformance/docs.md`, § @BeamMemory — where a module var lives on the BEAM):

> `#[@BeamMemory.<member>]` above a module `var` names its memory on erlang and
> beam. The member is one of `ProcessDict` (the default, which a bare `var`
> already means — writing it out loud records the choice where it is read), `Ets`
> or `PersistentTerm`. The only argument is `keyed: true | false`, default
> `false`, and it is a `Dict`-only argument: an `i32` has no key and neither has a
> list, which stores its whole value. Every part is checked at `botopink check`,
> in a project whose target is erlang or beam:
