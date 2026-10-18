# http_fetch_request

The reference text this cell shows (from `conformance/docs.md`, § The HTTP client, `io.http`):

> `io.http.fetch` has one typed surface (decision 623): `fetch(req: Request) -> @Task<@Result<Response,
> HttpError>>`. `Request(method, url, headers = [], body = null)` holds the `Method` (`.Get`, `.Post`, `.Put`,
> `.Delete`, `.Patch`, `.Head`, `.Options`), the URL, the `Header`s (`name`, `value`) and an optional `Bytes`
> body; a short GET is the record with its defaults, never a second signature. A failure is a variant of
> `HttpError` — `NotAllowedOnHost`, `Network(message)` or `Timeout` — matched by variant, and an HTTP error
> status (404, 500) is an `Ok` response with its `status`.
