# external_result_task_plain_value

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> The flag has one reading, so the checker holds it to it, at the annotation
> (decisions 487, 488, 490, 491):
>
> - `result: true` needs the return `Result<…, HostError>` or
>   `Async<Result<…, HostError>>` — a plain value, or an `Async<T>` that has no
>   `Result` inside it, is refused:
