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
  - `guide` / `GET /guide` / `GET /llms.txt` — cli-guide-spec
  - `help-json` + typed stderr errors + exits 0/5/80–119 — cli-output-spec
  - `feedback` dual-write + `POST|GET /v1/feedback` — cli-feedback-spec
  - `update` content-hash (`sha256[:12]`) verify-then-swap + nudge — cli-update-spec
  - On release: rebuild, write `docs/version.json` from `sha256sum ./poche`, upload the same bytes as the GitHub release asset

Docs: `docs/` (GH Pages). Changelogs via changelog-updater skill.
