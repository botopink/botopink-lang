# component_is_lambda

Decision 388 (1) as 809, 819 and 908 state it: a component at run time is a function over a `Scope` and a `Place`, and calling `C` runs nothing — `itens.map(Card)` answers components, which generic code keeps as values. `Lista` resolves its cards inside its own body with `use all` after its `use provide`, so each card reads the prefix it provided.

[src/main.bp](src/main.bp)
