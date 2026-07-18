# Changelog

## 0.2.1 — 2026-07-19

### Fixed

- Delete file blobs from disk, not only `_files` metadata
- Enforce `_files read` RBAC on HTTP downloads
- Return `201 Created` for REST creates and support it in the MFL SDK
- Handle browser CORS preflight with explicit methods/headers

### Added

- `GET /api/:collection/count?where=…`
- Equality/range index kind through CLI, admin API and SDK

## 0.2.0 — 2026-07-19

### Added

- Three compiled machin dogfood backends: Twitter, marketplace, car renting
- Machine bootstrap API (`/admin/schema`, `/admin/index`, `/admin/expose`)
- Schema modifiers: `!required`, `!unique`, `!now`, `!min=`, `!max=`, `!ref=`
- Atomic increment and compare-and-swap mutations
- Pagination offsets, total counts and numeric sorting
- Escaped SDK JSON and URL path segments

### Verified

- 13 dogfood gaps fixed
- Core smoke + all 3 backend smoke suites pass
- 100k insert bench: 185k docs/s final run (185–202k observed)
- Every `src/*.src` and example MFL source remains under 500 LOC

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
