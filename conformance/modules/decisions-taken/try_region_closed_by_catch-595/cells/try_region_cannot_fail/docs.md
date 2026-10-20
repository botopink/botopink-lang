# try_region_cannot_fail

The reference text this cell shows (from `conformance/docs.md`, § Results):

> Every `try` in a region fails with one error type. A second type is refused at its `try`,
> `try-region-errors-differ`, naming both: handle that failure on the spot (`try parseInt(raw) catch …`)
> or convert it (`catch throw …`). A region that holds no `try` cannot fail, and is refused
> `try-region-cannot-fail`:
