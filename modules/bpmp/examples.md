# bpmp — worked examples

Three end-to-end walk-throughs. Run them top-to-bottom — each builds on
the project state the previous step left behind.

## Example 1 — fresh project + first install

```bash
$ mkdir hello && cd hello
$ bpmp init --target commonJS --name hello
bpmp init: wrote botopink.json + botopink.lock.json
next steps:
  • run `bpmp install <name>` to add a framework
  • run `bpmp run -- build src/main.bp` to compile

$ cat botopink.json
{
  "name": "hello",
  "version": "0.0.1",
  "target": "commonJS",
  "entry": "src/main.bp",
  "src": "src/",
  "dependencies": [],
  "requires": {}
}

$ bpmp install erika@^0.0.1
bpmp install: added erika (^0.0.1) to botopink.json (dependencies + requires)
hint: the network resolver lands later in v0.beta.18 — re-run `bpmp install` once it's live to pin the commit + sha256.

$ cat botopink.json
{
  "name": "hello",
  "version": "0.0.1",
  "target": "commonJS",
  "entry": "src/main.bp",
  "src": "src/",
  "dependencies": [
    "erika"
  ],
  "requires": {
    "erika": "^0.0.1"
  }
}

$ bpmp list
Project
  name:    hello
  version: 0.0.1

Dependencies (1)
  • erika           ^0.0.1

Lockfile (0 pinned)
```

## Example 2 — locked replay on a fresh checkout

A teammate clones your repo. Their `botopink.lock.json` carries every
commit pin, so their tree resolves byte-for-byte to yours.

```bash
$ git clone repo && cd repo
$ ls botopink.lock.json   # already committed by you
$ bpmp install            # no args → replay
bpmp install: replaying 3 package(s) from botopink.lock.json
  • erika 0.0.1 commit=ff1122334455…
    (download path lands in v0.beta.18 follow-up; commit + sha256 are recorded)
  • jhonstart 0.1.2 commit=0011aabb22cc…
  • rakun 0.0.4 commit=1234abcd5678…

$ bpmp list
Project …
Dependencies (3)
Lockfile (3 pinned)
  • erika      0.0.1 (ff11223)
  • jhonstart  0.1.2 (0011aab)
  • rakun      0.0.4 (1234abc)
```

Note how the lockfile is the source of truth: `bpmp install` with no args
**never** re-resolves constraints — that's `bpmp sync`'s job. Replay
fetches by commit (`/archive/<commit>.tar.gz`), never by tag.

## Example 3 — compiler-hacker workflow (`dev` link)

You're working on the compiler itself; you want a project to pick up
your local `zig-out/` instead of a release tarball.

```bash
# In your botopink-lang clone:
$ cd ~/repos/botopink-lang
$ zig build install --prefix /tmp/dev-bp
# /tmp/dev-bp/bin/botopink is now your hot-rebuild binary.

# In your project:
$ cd ~/projects/my-app
$ bpmp use botopink dev --from /tmp/dev-bp/bin
bpmp use: dev → /tmp/dev-bp/bin (recorded at ~/.bpmp/botopink/versions/dev/dev.path)

$ bpmp run -- build src/main.bp
# Would exec /tmp/dev-bp/bin/botopink with BOTOPINK_LIB_ROOTS set to your installed packages.

# Iterate on the compiler:
$ cd ~/repos/botopink-lang
$ # edit … zig build install --prefix /tmp/dev-bp
$ cd ~/projects/my-app
$ bpmp run -- build src/main.bp   # picks up the new dev build automatically
```

The `dev` slot is **per-machine**: it stays linked across project switches.
To go back to a stable release: `bpmp use botopink <ver>` (once the live
HTTP path ships).

## Conflict resolution UX

If two of your deps want incompatible versions of a transitive dep, bpmp
refuses to silently pick:

```bash
$ bpmp install rakun
error: erika: incompatible constraints
  my-app      → ^0.0.1   (would resolve to 0.0.1)
  rakun       → ^0.0.2   (would resolve to 0.0.2)
hint: edit botopink.json:
  "requires": { "erika": "^0.0.2", … }
then re-run bpmp install.
```

You edit `requires.erika` to satisfy both, re-run, done. No backtracking,
no SAT solver — the failure mode is loud and the fix is explicit.

## Shell PATH setup

```bash
$ bpmp env
# Append to your ~/.bashrc:
export PATH="$HOME/.bpmp/bin:$PATH"

$ bpmp env --shell fish
# Add to ~/.config/fish/config.fish:
set -gx PATH $HOME/.bpmp/bin $PATH

$ bpmp env --shell pwsh
# Add to your PowerShell $PROFILE:
$env:Path = "$HOME/.bpmp/bin;" + $env:Path
```

`bpmp env` deliberately does **not** export `BOTOPINK_LIB_ROOTS` — that's
per-project state, set by `bpmp run` for the duration of one compile. A
globally-exported one would silently reach for whichever project last set
it.
