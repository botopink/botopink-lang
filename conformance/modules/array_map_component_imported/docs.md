# array_map_component_imported

The reference text this cell shows (from `conformance/docs.md`, § Comptime › Decorators):

> A decorator that reads `.hooks` records its meta after its module's bodies, so the page's
> meta is read from another module. A component the importing module lowers is lowered against
> the checked types of the module that wrote it: the calls on literals in its body (`5.toString()`,
> `[1, 2].map(Card)`) resolve there, whether or not the importer calls it. A component value the
> checker cannot follow (a parameter, a method, generic code) is an edge with `callee: null`:
