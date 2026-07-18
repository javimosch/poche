# AGENTS.md — poche

Agent-first headless CMS over [grange](https://github.com/javimosch/grange). No UI.

```sh
./build.sh
export POCHE_DB=./poche.data
./poche guide          # mental model (JSON)
./poche help-json      # command catalog
./test.sh              # smoke
```

Constraints:

- ≤500 LOC per `src/*.src` file
- Storage = grange only (`vendor/grange` → `~/ai/grange/src`)
- Single-actor HTTP (`listen`/`accept`) — do not use machweb `serve()` with the engine
- Adopt [cli-specs](https://cli-specs.intrane.fr/) (output / guide / feedback / update)

Docs: `docs/` (GH Pages). Changelogs via changelog-updater skill.
