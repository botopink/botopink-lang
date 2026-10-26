# variant_payload_without_name

The reference text this cell shows (from `conformance/docs.md`, § Decided, not yet implemented):

> These forms are **deliberately absent**, so that none reads as unfinished work:
>
> | Form | What the compiler says |
> |---|---|
> | `type Shape { Circle(i32) }` — a variant payload with no field name | `error[field-needs-name]`: a field with no name, at the payload, naming `Variant(field: T)`. A payload nobody can name is a payload no `case` arm can bind |
