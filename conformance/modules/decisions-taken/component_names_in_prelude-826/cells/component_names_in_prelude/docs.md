# component_names_in_prelude

Decision 826: `Composition<T>`, `Composable<T>` and `Component<T>` are written bare, with no
import; `Component<T>` is opened into its two members only at an `is` — a component call is no
`Composable`, it is the `Composition` —, and a function over the scope and the place is a
`Composition<T>` where a `Component<T>` is expected.

[src/main.bp](src/main.bp)
