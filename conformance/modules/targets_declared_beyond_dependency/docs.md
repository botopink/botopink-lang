# targets_declared_beyond_dependency

The same program declaring `"targets": ["commonJS"]` is held to it (decisions 676, 770): `beamkit` declares `erlang` alone, so the manifest is refused at `beamkit`'s line, `dependency-target-missing`, naming `commonJS`, on every build target.
