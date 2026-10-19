# comptime_enum_in_record

The reference text this cell shows (from `conformance/docs.md`, § Compile-time evaluation):

> An enum value crosses a `comptime` both ways, a leaf under a section included
> (§ Sections of an enum): `comptime name(.Pad.All.4)` passes it in — alone, in
> an array, inside a payload variant — and a `comptime` whose type is the enum
> writes its answer back as the enum's constructor, as it writes an enum value in
> a record's field (a generic record's field typed by its parameter included). A section path written in a
> function the `comptime` reaches is resolved where that function is inferred,
> so, as with a template call, the function is declared before the `comptime` —
> otherwise the `comptime` is refused, naming the path. A decorator's argument
> (`#[mark(.Pad.All.4)]`, read as `tokens.value`) and the functions a decorator
> reaches carry the same values.
