# Decision 321 — Two providers of one type are told apart by a label, checked at compile time.

The example provides two beans of the type `Database`. `analyticsDb` carries `#[qualifier("reports")]`, and the label is the author's choice: it is not the function's name, and nothing resolves a bean by a function's name. `mainDb` carries `#[primary]`. Both markers record typed meta on the provider, and the registry keys each provider by its type and its label.

`main` asks the context with the type itself every time. `resolveNamed(Database, "reports")` prints `pg://replica/analytics`. `resolveNamed(Database)` names no label, so it answers the `#[primary]` provider and prints `pg://primary/app`. The constructor of `ReportJob` uses the same marker on a field. Its `db` field, labelled `"reports"`, is the replica. Its `fallback` field carries no label and gets the primary, so the last line prints both URLs.

Every label is a `comptime` argument checked against the registry at build. Writing `"report"` instead of `"reports"` would fail the build with an error naming the labels that exist. So would a second `#[primary]` on `Database`, a second provider labelled `"reports"`, or an unlabelled request after `#[primary]` is removed.

The compiler's part is the `comptime` argument and the typed meta the markers record. The registry is rakun's, and the example imports `rakun`, which this repository's drafts declare no dependency on.

Cells in this repository that also bear on it: none.

[draft/main.bp](draft/main.bp)
