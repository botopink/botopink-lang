# record_update_spread

The reference text this cell shows (from `conformance/docs.md`, § type — records):

> A record is immutable: a field is never assigned. A changed copy is the update
> form — `..base` and the fields that change, by label; every other field is read
> from `base`, which is a name or a path of names (a call there is refused, since
> it would run once per copied field — bind it with `val` first):
