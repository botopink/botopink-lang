# component_base_parameter

The reference text this cell shows (from `conformance/docs.md`, § Migrating from the effect annotations):

> Decision 354 leaves one wrapper, `@Component<R>`, and `@Renderable` as a bare marker: `@Component<C, R>` is a type-arity error (`generic-arg-count-exceeded`) naming `@Component<R>`, located on the base; `@Renderable<T>` is the same error at the `<`, naming `@Renderable`; and the owner marker `@Context<C>` is `context-marker-removed`, naming `implement @Renderable`.
