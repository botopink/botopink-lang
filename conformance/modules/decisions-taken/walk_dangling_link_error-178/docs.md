# Decision 178 — † A dangling link under `fs.walk` is an `Error` naming the link, on both targets — not skipped

The example makes a directory with one file and one link, `gone.bp`, which points at nothing. `fs.walk` does not skip the link: it answers `Error(Other(…))`, the message naming the link by its path relative to the root, `fs.walk: dangling link "gone.bp"`. The text is the same on commonJS and erlang. Before the link exists, the same walk answers `Ok(["page.bp"])`. The link is made with a host binding of the example's own, `linkTo`, because std has no public function that makes one.

The program prints `page.bp` and then `fs.walk: dangling link "gone.bp"`.

Cells in this repository that bear on it: `modules/decisions-taken/fs_walk_dangling_link_not_found-711/cells/std_fs_walk_root_spellings` (the dangling link under two spellings of the root).

[draft/main.bp](draft/main.bp)
