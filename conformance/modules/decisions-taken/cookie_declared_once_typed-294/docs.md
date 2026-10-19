# Decision 294 — A cookie is declared once, typed:

A cookie is declared once, typed, with its attributes beside its name. `http`'s `Cookie<T>` is the library's; the
example declares a small one of its own to show the shape. `sessionCookie` is a module `val`, its type argument the
value it carries — `SessionId`, a one-field record —, its name the browser's string written once, its attributes
labelled arguments with defaults; `themeCookie` carries a `bool` and takes every default. Whoever writes or clears the
cookie reaches the declaration, so the attributes come from it and are never repeated: setting the session prints
`session=abc123; HttpOnly; Secure; Max-Age=2592000`, clearing it `session=; Max-Age=0`, and the theme `dark=true`. A
value of another type is refused where `set` is called, `T` being fixed where the cookie was declared.

[draft/main.bp](draft/main.bp)
