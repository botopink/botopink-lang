# primitive_width_redeclared_refused

Decisions 617 (1) and 639: a width is declared once, in std's prelude, as `pub type i32 implement Signed { … }` — a
type with no field list, since the language gives its values. The same form written in a module is refused at the name,
`primitive-type-redeclared`, as any type named like a literal's type is (`primitive_type_redeclared_refused`). It used to
stop at the parse, `type-without-field-list`.
