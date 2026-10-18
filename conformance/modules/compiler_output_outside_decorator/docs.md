> Decision 575 (3) — the outputs (`compiler.setMeta`, `addMember`, …) write
> to the annotated declaration, and only a decorator has one: a function
> whose first parameter is no `syntax` is refused at the output
> (`compiler-output-outside-decorator`).
