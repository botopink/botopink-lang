# import_std_groups

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> | Where | Modules |
> |---|---|
> | the root (pure) | `collections` (`Dict`, `Set`, `Queue`, `Order` — a constructor is called on its type: `Dict.empty()`, `Dict.ofEntries([#("a", 1)])`, `Set.fromList(xs)`), `math`, `path`, `url`, `querystring`, `regex`, `unicode`, `string_builder`, `encoding`, `hash`, `escape`, `async`, `bpp` (the four annotations a framework marks its `.bpp` roles with — `#[bpp.html]`, `#[bpp.style]`, `#[bpp.htmlPrelude]`, `#[bpp.stylePrelude]` — and `Prelude`, decision 361); `erlang` and `beam` (the target's surface) |
> | `io` | `io.fs`, `io.http`, `io.net`, `io.clock`, `io.random`, `io.os`, `io.env`, `io.process` |
> | `testing` | `testing.asserts`, `testing.mocks` (`testing.snapshots` is the `snap` library, decision 391) |
