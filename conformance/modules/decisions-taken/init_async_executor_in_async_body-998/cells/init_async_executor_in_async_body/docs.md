# init_async_executor_in_async_body

The reference text this cell shows (from `conformance/docs.md`, § A top-level `comptime { … }`):

> Its executor is a plain lambda `{ -> … }` or an `async` one `{ async -> … }`, the marker inside the brace; an
> `await` in an executor needs the marker, as in any lambda. An `async` executor stands only where a run-time call
> expanded inside an `async` body writes its statements there, its `await`s that body's.
