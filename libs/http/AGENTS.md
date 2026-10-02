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

**Bundled.** `build.zig`'s `bundled_packages` names it after `routing` (it imports std
only): any program's `from "http"` loads the copy embedded in the compiler, as
`http/<module>` (atoms `http@<module>`), with no `dependencies` entry and never from this
directory; listing `http` in `dependencies` is refused. An edit here reaches a consumer
only through a rebuilt compiler.

`.bp` only (decision 117): the one host cell is the `wide` widening in `lexical.bp`, an
inline `#[@External]` template on both targets. It imports `std` (`encoding`, `io.clock`)
only. The module names avoid every name std or a framework exports (erika exports `range`,
so the range codec is `byteRange`); functions are reached through their module, and a
bare import of `mime.extensionOf` or `cacheControl.render` would meet rakun-web's,
onze-assets' and jhonstart's own `extensionOf` / `render`.

## Tree

```text
http/
├── botopink.json      "name": "http", "target": "erlang", "targets": ["erlang", "commonJS"]
├── AGENTS.md
├── src/root.bp        mod lexical; pub mod cookie; pub mod accept; pub mod mime; pub mod status; pub mod date; pub mod byteRange; pub mod cacheControl;
├── src/lexical.bp     internal: ASCII character classes (token, cookie-octet, printable), charOf/sub, digits, trimOws, idiv, wide
├── src/cookie.bp      CookieAttributes, parse, get, serialize, formatHeader
├── src/accept.bp      MediaRange, LanguageRange, qValue, parseAccept, mediaQuality, negotiateMedia, tokenQuality, negotiateToken, parseAcceptLanguage
├── src/mime.bp        extensionOf, contentTypeOf, isText
├── src/status.bp      reasonPhrase
├── src/date.bp        formatHttpDate, parseHttpDate
├── src/byteRange.bp   ByteRange, parseRange, contentRange
├── src/cacheControl.bp CacheDirectives, directives, with* builders, render, staticFile
└── test/              cookie_test · accept_test · date_test · codecs_test (mime, status, byteRange, cacheControl) — suite `http:`
```

Consumers: `import {cookie, accept} from "http";` then `cookie.get(header, "SID")`,
`accept.negotiateMedia(req.header("accept"), offered)`.

## Surface and rules

| Module | Surface | Rules |
|---|---|---|
| `cookie` | `type CookieAttributes(path, domain, maxAge: ?i32, httpOnly, secure, sameSite)`; `parse(header) -> Array<#(string, string)>`; `get(header, name) -> ?string`; `serialize(name, value, attrs) -> string`; `formatHeader(pairs) -> string` | **Reading**: split on `;`, SP/HTAB trimmed, empty chunks skipped, a chunk without `=` is no cookie. A pair needs a token name (case-sensitive) and an RFC 6265 `cookie-value` (cookie-octets, one optional `"…"` pair stripped) whose escapes are all `%XX` and none a control character (`%00`–`%1F`, `%7F`); it is then percent-decoded (std `encoding.percentDecode`). Anything else is REFUSED — and a refused chunk still claims its name, so the first occurrence decides (`a=%zz; a=2` reads `a` absent; `a=1; a=2` reads `1`). `parse` answers each name once, in header order, refused ones left out. **Writing**: `name=<percentEncode(value)>; Path; Domain; Max-Age; HttpOnly; Secure; SameSite`, each only when set (`maxAge: null` omits `Max-Age` — a session cookie). Raises on: a non-token name, a value or attribute outside printable ASCII (no byte type — encode it first), a `Path` with `;`, a `Domain` outside letters/digits/`-`/`.`, a `SameSite` other than `Strict`/`Lax`/`None`, `SameSite=None` without `Secure`, `__Secure-` without `Secure`, `__Host-` without `Secure` + `Path=/` + no `Domain`. `formatHeader` writes a request `Cookie` header (`a=1; b=x%20y`) that `parse` reads back |
| `accept` | `type MediaRange(mainType, subType, params: Array<#(string, string)>, q)`; `type LanguageRange(tag, q)`; `qValue(text) -> i32`; `parseAccept(header) -> Array<MediaRange>`; `mediaQuality(accept, mediaType) -> i32`; `negotiateMedia(accept, offered) -> string`; `tokenQuality(header, token) -> i32`; `negotiateToken(header, offered) -> string`; `parseAcceptLanguage(header) -> Array<LanguageRange>` | Weights per mille. `qValue` is decision 182's grammar exactly — `0[.ddd]` / `1[.000]`, at most three decimals, digits only, no whitespace — and anything else is 0. An element without `q` weighs 1000. An element that does not parse (not `type/subtype` tokens, `*/x`, a parameter not `token=token` / `token="…"` without `"` or `\` inside, a coding not a token, a language range outside RFC 4647 § 2.1) is dropped. `mediaQuality`: the most specific matching range decides (`type/subtype` > `type/*` > `*/*`, each range parameter adding specificity and having to be present with the same value in the media type), the first of equally specific ones; an empty header weighs 1000. `negotiate*`: highest weight above 0, ties to the order of `offered`, `""` for none. `tokenQuality`: own element, else `*`, else 0 — `identity` is 1000 unless excluded (RFC 9110 § 12.5.3), so an empty `Accept-Encoding` accepts identity only. `parseAcceptLanguage`: weight descending, header order among equals, zero weights kept (they exclude), tags as written |
| `mime` | `extensionOf(pathOrExt)`; `contentTypeOf(pathOrExt) -> string`; `isText(mediaType) -> bool` | the extension is the text after the last `.` of the last `/` segment, or the whole segment without a `.` (`png` → `png`), lowercase. One table (rakun-web's `static.bp` set: html/htm, css, js/mjs, txt, json/map, xml, svg, png, jpg/jpeg, gif, webp, avif, ico, woff, woff2, wasm, pdf); `text/*` types carry `; charset=utf-8`; anything else is `application/octet-stream`, never a guess. `isText` is `text/*`, parameters and case ignored |
| `status` | `reasonPhrase(code) -> string` | RFC 9110 § 15 plus 103, 425, 428, 429, 431, 451, 511; any other code (418 included) is `""` — the phrase is optional on the wire and never invented |
| `date` | `formatHttpDate(epochMillis: i64) -> string`; `parseHttpDate(text, nowMillis: i64) -> @Result<i64, string>` | writes IMF-fixdate over std `clock.toCivil` (UTC), truncated to the second; raises for a year outside 0000–9999. Reads IMF-fixdate, RFC 850 and asctime exactly (case-sensitive names, fixed widths, `GMT`, hours 00–23, seconds 00–60, a real calendar day, the day name matching the date); the epoch is a days-from-civil count in botopink. `nowMillis` only places an RFC 850 two-digit year (its century, or the one before when that is more than 50 years ahead — § 5.6.7), so the function stays pure. `Error` texts are `http.parseHttpDate: "<text>" <why>` |
| `byteRange` | `type ByteRange(status, first: i64, last: i64)`; `parseRange(header, size: i64) -> ByteRange`; `contentRange(r, size) -> string` | one range: 206 with `first`–`last` (inclusive, clamped) for `a-b` / `a-` / `-n`; 416 when it starts at or past the end, is `-0`, or the size is 0; 200 (ignore, send whole) for no header, a unit other than `bytes` (case-insensitive), more than one range, whitespace, a sign, `b < a`, a number beyond 2^53 − 1. `first`/`last` are −1 off 206. `contentRange` → `bytes a-b/size`, `bytes */size`, `""` |
| `cacheControl` | `type CacheDirectives(scope, maxAge: ?i32, sharedMaxAge: ?i32, noStore, noCache, mustRevalidate, proxyRevalidate, noTransform, immutable)`; `directives()`; `withPublic`, `withPrivate`, `withMaxAge(d, s)`, `withSharedMaxAge(d, s)`, `withNoStore`, `withNoCache`, `withMustRevalidate`, `withProxyRevalidate`, `withNoTransform`, `withImmutable`; `render(d) -> string`; `staticFile(maxAge, immutable) -> string` | `render` writes scope, `no-store`, `no-cache`, `max-age`, `s-maxage`, `must-revalidate`, `proxy-revalidate`, `no-transform`, `immutable`, joined by `, `; nothing set is `""`. Raises on public + private, a negative age, `no-store` with public / max-age / s-maxage / immutable, `immutable` without `max-age`. `staticFile` is rakun-web's `cacheHeader`: `no-cache` for an age ≤ 0, else `public, max-age=N[, immutable]` |

## Testing

```sh
cd libs/http
../../zig-out/bin/botopink test --target erlang
../../zig-out/bin/botopink test --target commonJS
../../zig-out/bin/botopink format --check src test
```

Every expected text is a literal, the same on both rows. `zig build test-libs -- --lib http`
runs the two cells.

## Language notes (measured)

- A `?#(A, B)` (an optional tuple) does not parse as a type — `unexpected '#'`; the
  codecs answer a small record with an `ok` flag instead.
- std `encoding.percentDecode("100%")` is `Ok("100%")` on erlang (`uri_string:unquote`
  keeps a trailing lone `%`) and an `Error` on commonJS; `cookie` checks the escape
  grammar itself before decoding.
- Non-ASCII literals are avoided in sources and tests (erlang truncates them and
  `String.length` can raise on them); every message text is ASCII.
