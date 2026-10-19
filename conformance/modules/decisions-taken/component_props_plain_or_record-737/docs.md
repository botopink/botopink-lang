# Decision 737 — (a): a component takes its props as plain parameters or as one record parameter `..props: R` — 529 (1), (2) stand whole.

Both forms of a component's props stand. `PlainCard` takes them as ordinary parameters, `title` and `featured` with its default; a tag passes each attribute as the labelled argument of that name (`<PlainCard title="Olá" featured />`), and the call here does the same, printing `Olá` and `Olá *`. `RecordCard` takes one record parameter, `..props: CardProps`: from outside, `CardProps`' fields are its parameters, and inside the body reads the record `props`. Only into a record parameter may a spread go — `RecordCard(..p, featured: true)`, as `<RecordCard {..p} featured />` would — printing `Oi *`, and `RecordCard(title: "Tchau")` fills the rest from `CardProps`' defaults, printing `Tchau`. Each component's value is run at the root of a render to read its element.

Cells in this repository that also bear on it: `modules/decisions-taken/component_props_plain_or_rest-529/cases/record_param`, `modules/decisions-taken/component_props_plain_or_rest-529/cases/record_param_spread_other_type`, `modules/decisions-taken/record_spread_copies_fields-359/cases/record_spread`.

[draft/main.bp](draft/main.bp)
