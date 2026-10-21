# json_is_string

`Json.isString()` (decision 941) answers `true` for a `Str` and `false` for every other kind — `Null`, `Bool`, `Num`, `Arr` and `Obj` — beside `isObject`; an empty string is still a `Str`. It throws nothing and answers no `Result`, like `kindName` and `isObject`.
