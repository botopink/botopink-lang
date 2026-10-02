# http

> Path: `libs/http/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)

The bundled `http` library (decision 196; the criterion is decisions 115–117): the codecs
of HTTP semantics that rakun and onze both read and write — **one** implementation
compiled for erlang and commonJS, so a server and a test client, or two frameworks,
cannot disagree byte for byte. Pure codecs: no wire parser (the HTTP/1.1 head parsers
wait on a byte type, lg2-a), no compression, no ETag (std's `hash.etag` / `weakEtag` /
`matches` own it), no state, no framework name under `src/`.

Rules where an RFC decides are the RFC's (6265, 9110, 9111, 7233), and everywhere else
the most restrictive reading (decision 67): a duplicate cookie name keeps its FIRST
value (decision 181), one strict q-value grammar for media, encodings and languages
(decision 182), and a line that cannot be written correctly raises instead of reaching
the wire. No exported name repeats one std or a framework exports (decision 163): the
modules are reached qualified (`cookie.parse`, never a bare `cookies`).

`.bp` only (decision 117): the one host cell is the `wide` widening in `lexical.bp`, an
inline `#[@External]` template on both targets. It imports `std` (`encoding`) only.

## Tree

```text
http/
├── botopink.json      "name": "http", "target": "erlang", "targets": ["erlang", "commonJS"]
├── AGENTS.md
├── src/root.bp        mod lexical; pub mod cookie;
├── src/lexical.bp     internal: ASCII character classes (token, cookie-octet, printable), charOf/sub, digits, trimOws, idiv, wide
├── src/cookie.bp      CookieAttributes, parse, get, serialize, formatHeader
└── test/              cookie_test (suite `http:`)
```

Consumers: `import {cookie} from "http";` then `cookie.get(header, "SID")`.

## Surface and rules

| Module | Surface | Rules |
|---|---|---|
| `cookie` | `type CookieAttributes(path, domain, maxAge: ?i32, httpOnly, secure, sameSite)`; `parse(header) -> Array<#(string, string)>`; `get(header, name) -> ?string`; `serialize(name, value, attrs) -> string`; `formatHeader(pairs) -> string` | **Reading**: split on `;`, SP/HTAB trimmed, empty chunks skipped, a chunk without `=` is no cookie. A pair needs a token name (case-sensitive) and an RFC 6265 `cookie-value` (cookie-octets, one optional `"…"` pair stripped) whose escapes are all `%XX` and none a control character (`%00`–`%1F`, `%7F`); it is then percent-decoded (std `encoding.percentDecode`). Anything else is REFUSED — and a refused chunk still claims its name, so the first occurrence decides (`a=%zz; a=2` reads `a` absent; `a=1; a=2` reads `1`). `parse` answers each name once, in header order, refused ones left out. **Writing**: `name=<percentEncode(value)>; Path; Domain; Max-Age; HttpOnly; Secure; SameSite`, each only when set (`maxAge: null` omits `Max-Age` — a session cookie). Raises on: a non-token name, a value or attribute outside printable ASCII (no byte type — encode it first), a `Path` with `;`, a `Domain` outside letters/digits/`-`/`.`, a `SameSite` other than `Strict`/`Lax`/`None`, `SameSite=None` without `Secure`, `__Secure-` without `Secure`, `__Host-` without `Secure` + `Path=/` + no `Domain`. `formatHeader` writes a request `Cookie` header (`a=1; b=x%20y`) that `parse` reads back |

## Testing

```sh
cd libs/http
../../zig-out/bin/botopink test --target erlang
../../zig-out/bin/botopink test --target commonJS
../../zig-out/bin/botopink format --check src test
```

Every expected text is a literal, the same on both rows.

## Language notes (measured)

- A `?#(A, B)` (an optional tuple) does not parse as a type — `unexpected '#'`; the
  codecs answer a small record with an `ok` flag instead.
- std `encoding.percentDecode("100%")` is `Ok("100%")` on erlang (`uri_string:unquote`
  keeps a trailing lone `%`) and an `Error` on commonJS; `cookie` checks the escape
  grammar itself before decoding.
- Non-ASCII literals are avoided in sources and tests (erlang truncates them and
  `String.length` can raise on them); every message text is ASCII.
