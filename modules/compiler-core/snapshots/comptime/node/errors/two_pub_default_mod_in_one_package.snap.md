----- SOURCE CODE
pub default mod alpha;
pub default mod beta;

----- ERROR
error: a package declares at most one `pub default mod` and one `pub default fn`

  hint: Remove the duplicate default declaration; a package has a single default module and handler.
