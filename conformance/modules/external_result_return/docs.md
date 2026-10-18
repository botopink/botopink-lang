# external_result_return

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> The flag has one reading, so the checker holds it to it, at the annotation
> (decisions 487, 488, 490, 491):
>
> - `result: true` needs the return `Result<…, HostError>` or
>   `Task<Result<…, HostError>>` — a plain value, or a `Task<T>` that has no
>   `Result` inside it, is refused:
