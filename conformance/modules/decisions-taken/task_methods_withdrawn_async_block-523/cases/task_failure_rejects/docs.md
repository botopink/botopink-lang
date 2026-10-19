# task_failure_rejects

The reference text this cell shows (from `conformance/docs.md`, § Tasks, *Per backend*):

> **An `Async<Result<T, E>>` rejects its Promise with `E` and resolves it with
> the bare `T`** (decision 432) — no `{ ok }` / `{ error }` wrapper: JavaScript
> that awaits a botopink task writes `try { await t } catch (e) { … }`, and the
> `.d.ts` declares `Promise<T>` under `/** @throws {E} */`. A failing task nobody
> awaits is not an unhandled rejection.
