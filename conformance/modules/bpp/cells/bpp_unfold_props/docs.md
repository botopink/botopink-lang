# bpp_unfold_props

The reference text this cell shows (from `conformance/docs.md`, § A `.bpp` file):

> - the header's declarations — `import`, `type`, `pub …`, a private `fn`, a
>   `test`, a decorated declaration — stay at module level, as written;
> - the module's anonymous `pub default fn (props: Props) -> R` — `()` when the
>   header declares no `Props` — whose body is the header's statements (`val`,
>   `var`, `use`, `if`, an expression statement) in order, so they read `props`;
