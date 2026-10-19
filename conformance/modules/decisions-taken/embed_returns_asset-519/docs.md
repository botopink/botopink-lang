# Decision 519 — `@embed(comptime path) -> Asset` replaces `@embedFile` / `@embedBytes`; a `Build` builtin, its file embedded in the artifact.

[refused/src/cases/embed_file_missing/mod.bp](refused/src/cases/embed_file_missing/mod.bp)
[refused/src/cases/embed_path_absolute/mod.bp](refused/src/cases/embed_path_absolute/mod.bp)
[refused/src/cases/embed_path_not_known/mod.bp](refused/src/cases/embed_path_not_known/mod.bp)
[cells/embed_path_outside_package/src/main.bp](cells/embed_path_outside_package/src/main.bp)
[cells/embed_text_file/src/main.bp](cells/embed_text_file/src/main.bp)
[cells/embed_text_not_utf8/src/main.bp](cells/embed_text_not_utf8/src/main.bp)
[cells/embed_through_comptime_param/src/main.bp](cells/embed_through_comptime_param/src/main.bp)
