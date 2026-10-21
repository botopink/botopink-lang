# dict_bump

The reference text this cell shows (from `conformance/docs.md`, § `compiler.beamMemory` — where a module var lives on the BEAM):

> On any other `Dict`, `bump(key, by)` is `insert(key, (at(key) ?? 0) + by)`, on every target: an
> absent key counts from 0, and the dict it was called on is unchanged:
