# Decision 400 — A cookie's hooks are nouns in cardume's family — `cookieValue`, `cookieState`, `cookieSetter`, `cookieReset`.

The example declares `sessionCookie` once, as `http`'s `Cookie<SessionId>`, with its attributes. Every hook then takes that declaration as a value. The hooks are nouns, and `use` does the activating, so the program writes `use cookieSetter(sessionCookie)` and never `useCookieSetter`.

Three bodies write. Each is a `component fn` answering `Component<Response>`, so each may `use`. `login` takes the setter, a `fn(v: SessionId)`, and sets `s-42`. `logout` takes the reset, a `fn()`, and clears the cookie. `renew` takes the state: it reads `.value`, writes `.set(v)`, and turns `s-42` into `s-42-renewed`. Nothing written at a call site carries an attribute. The three `Set-Cookie` lines `main` prints all carry the declaration's `HttpOnly` and `Secure`, the last one clearing the cookie.

The page, `Greeting`, only reads. `use cookieValue(sessionCookie)` answers `?SessionId`, so the request carrying `session=s-42` renders `<p>s-42</p>`. The one carrying an undecodable `%zz` renders `<p>guest</p>`, because a value that does not decode is `null` exactly as an absent one is. Writing `cookieState`, `cookieSetter` or `cookieReset` inside `Greeting` would be refused at build, since a render writes no cookie.

The compiler's part is the `use` of a hook inside a `component` body, and the hooks list a framework's decorator reads to refuse a write in a render. The hooks and `Cookie<T>` are the libraries': the example imports `http`, `rakun` and `rakun-bpp`, which this repository's drafts declare no dependency on.

Cells in this repository that also bear on it: none.

[draft/main.bp](draft/main.bp)
