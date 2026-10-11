# index_user_type

The reference text this cell shows (from `conformance/docs.md`, § Indexing and slicing):

> So indexing is not a privilege of the three built-in collections. `Array<T>`
> answers `Index<i32, T>` and `Slice<T[]>`, `string` answers `Index<i32, string>`
> and `Slice<string>`, `Dict<K, V>` answers `Index<K, V>` — and **your own type
> becomes indexable by answering them**, with nothing added to the compiler:
