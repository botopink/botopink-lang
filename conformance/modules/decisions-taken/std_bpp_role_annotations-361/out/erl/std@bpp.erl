-module(std@bpp).

%%% std/bpp — the contract between the toolchain and a framework that unfolds

%%% `.bpp` files (decision 361). An application names one package in its

%%% manifest, `"bpp": "jhonstart"`, and the toolchain finds four roles in that

%%% package by these annotations — nothing else about the package is known to

%%% it:

%%% 

%%%   `#[bpp.html]`         the template function the markup unfolds onto

%%%                         (exactly one in the package);

%%%   `#[bpp.style]`        the template function the style section unfolds

%%%                         onto (at most one);

%%%   `#[bpp.htmlPrelude]`  an item of the markup's prelude, marked where it is

%%%                         declared (decision 589): a `.bpp` file's markup

%%%                         sees it by its plain name without importing;

%%%   `#[bpp.stylePrelude]` the same for the style section (at most one).

%%% 

%%% A module takes no annotation (315), so a prelude is marked by a `val` it

%%% declares — `#[bpp.htmlPrelude] pub val prelude = bpp.Prelude();` — whose

%%% value is the empty record `Prelude`. Each annotation is a decorator in

%%% 302's shape and checks only where it sits: a template function — its

%%% first parameter `syntax q: string`, answering `R` (275 reads `R` from it,

%%% decision 578) — for the two template roles, a

%%% `val` for the two prelude roles. How many of each a package carries, and

%%% what else a prelude module declares, is the toolchain's check

%%% (`compiler-cli`, front 116).

%%% 

%%% A root module (decision 106): pure, no import.

%% import DeclKind

% The value of a prelude module's marker `val`.

%% type Prelude: 

% The markup's unfold target: the template function `html """…"""` a `.bpp`

% file's markup becomes.

% The style section's unfold target: the template function the section

% between `--- style ---` and `---` becomes (`use <style> """…""";`).

% The markup's prelude (decision 589): each item marked where it is declared

% — a `val`, a `fn` or a `type` — is one name a `.bpp` file's markup sees

% without importing it.

% The style section's prelude: the marker `val` of the module whose imports

% a `.bpp` file's style section resolves through.

