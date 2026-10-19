# page_settings_are_page_arguments

Decision 290: a page's settings are arguments of `#[page]`, beside its route. `revalidate:
clock.hours(1)` is a call of an `Any` std function over a literal, so it is known at build (decision
380) and the decorator reads it: `PageSettings` records `3600000` milliseconds and
`dynamicParams: false` for `blogPost`, the defaults for `about`. wasm is left out until std's
`io/clock` links there (its host has no wasm cell).
