# Decision 396 — Markdown, YAML and JSON are three libraries of their own — `markdown`, `yaml`, `json` (`botopink/{markdown,yaml,json}` at `repository/{markdown,yaml,json}`, 326's rule) — and std knows nothing of JSON.

The example asks std for JSON and is refused. std knows nothing of JSON: `json` is a library of its own, beside `yaml` (one YAML subset read into `json`'s `Json`) and `markdown` (a tree of its own that names no framework). A consumer declares it as a dependency and imports `from "json"`. So `import {json.decode} from "std";` is refused at the import, naming a std module that does not exist. The first line of `main` shows what std keeps: `escape.scriptJson` takes a `string` (already JSON text, encoded by whoever made it) and escapes it for a `<script>` element, without parsing or building a JSON value. Written against the library, the program would declare `"json"` in its manifest and write `import {decode} from "json";`.

Cells in this repository that bear on it: `modules/std_json_on_every_target` (std's `json` module as it stands until the move).

[draft/main.bp](draft/main.bp)
