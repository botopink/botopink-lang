# Decision 631 — (b), in one type: a `compiler.Field<T>` has a run-time form, its constructor over the owner type and the name — a `comptime` whose value holds a field splices `Field(Book, "pages")` —; `type`, `annotations` and `defaultValue` are build members, refused in a run-time body.

[cases/meta_field_tuple_and_field_key/src/main.bp](cases/meta_field_tuple_and_field_key/src/main.bp)
[cases/meta_field_compared_by_owner/src/main.bp](cases/meta_field_compared_by_owner/src/main.bp)
[cases/meta_field_build_member_at_run_time/src/main.bp](cases/meta_field_build_member_at_run_time/src/main.bp)
