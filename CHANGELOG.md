# Changelog

## 0.1.0 — 2026-07-19

### Added

- Agent-first headless CMS over grange: schema, data CRUD, RBAC, file blobs
- Single-actor HTTP serve: REST `/api/<coll>` + long-poll `/watch`
- cli-specs: `guide`, `help-json`, output contract, `feedback`, `update`
- `poche bench --n 100000` performance gate
- Docs site (`docs/`) + monthly changelog pages
- Upstream grange: split `engine.src` / `registry.src` (≤500 LOC)

### Notes

- Storage is grange-only (no SQLite path)
- No Admin UI by design
