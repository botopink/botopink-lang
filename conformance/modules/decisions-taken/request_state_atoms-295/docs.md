# Decision 295 — Request state is atoms, read and written through `use`

The example declares two request-scoped atoms of one type, `currentUser` and `impersonator`, both `atom<User>(null)`. Neither has a string key. Each atom is its declaration, so the two never meet even though they hold the same type, and nothing like `LocalKey<T>("user")` exists that could clash with a name at run time.

The middleware `authenticate` is a `component fn` answering `Component<Response>`, so it may `use`. It takes `use atomSetter(currentUser)` and sets `ana`. The handler `whoami` reads both atoms with `use atomValue(…)`, each answering `?User`. In the first request, which runs `authenticate` before `whoami`, it prints `ana / nobody`: only `currentUser` was written. The second request runs no middleware and prints `nobody / nobody`, because the atoms live in a store per request and that store starts empty each time. The request is the root context rakun's pipeline provides, so the hooks find their store there without the program passing it.

The compiler's part is `use` in a `component` body and an atom's identity being its declaration (281). The atoms are cardume's and the request store is rakun's: the example imports `cardume`, `rakun-cardume` and `rakun`, which this repository's drafts declare no dependency on.

Cells in this repository that also bear on it: none.

[draft/main.bp](draft/main.bp)
