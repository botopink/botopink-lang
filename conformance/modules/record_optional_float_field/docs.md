# record_optional_float_field

The reference text this cell shows (from `conformance/docs.md`, § Optionals):

> An optional holds any type: a record's `?f64` field holds a float or `null` and
> reads back as either, and an optional of an enum with a payload variant holds a
> variant or `null`. A leading dot where a `?Place` is expected names `Place`'s
> variant (`.Here` is `Place.Here`):
