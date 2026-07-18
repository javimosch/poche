# Dogfood gaps — real backend examples

Goal: build three machin backends in `examples/` and turn every real integration
friction into a tested poche improvement.

| # | Found while building | Fix | Status |
|---|---|---|---|
| 1 | Apps could not bootstrap schemas/indexes/exposure over HTTP | Admin bootstrap API + SDK helpers | fixed |
| 2 | Social profiles/posts could be created without identity/content | Required fields via `field:type!`, enforced in CLI and HTTP creates | fixed |
| 3 | A typo in an app schema silently became an unusable runtime type | Strict schema syntax/type/duplicate validation | fixed |
| 4 | Duplicate Twitter handles were accepted | `!unique` field modifier with create/update conflict checks | fixed |
| 5 | Every app had to trust clients to write timestamps | `!now` server-side integer timestamp modifier | fixed |
| 6 | Marketplace accepted negative prices/stock and absurd quantities | `!min=` / `!max=` numeric constraints | fixed |
| 7 | Orders/products could reference missing customers, sellers or products | `!ref=<collection>` referential validation | fixed |
| 8 | Read-then-write stock changes could lose concurrent updates | Atomic `/increment` mutation + SDK helper | fixed |
| 9 | Two buyers could both reserve the same last stock | Atomic `/compare-swap` with HTTP 409 on stale value | fixed |
| 10 | Fleet/catalog pages could not request the next page or know total matches | `offset` pagination with stable `count` + `total` metadata | fixed |
| 11 | Timelines, prices and fleet results could not be ordered | Numeric `sort` + ascending/descending query support | fixed |
| 12 | Quotes/newlines in real titles, bios and names broke SDK-built JSON | SDK JSON escaping + URL-encoded path segments | fixed |
| 13 | Public list routes could accidentally return/sort unbounded datasets | Default 50, max 1000, offset cap, numeric-sort validation | fixed |
| 14 | File deletion left orphaned bytes on disk | Remove the blob before deleting `_files` metadata | fixed |
| 15 | Any authenticated token could download files | Enforce `_files read` permission (admin still bypasses) | fixed |
| 16 | Apps needed a full page just to count matches | `GET /api/:collection/count` + SDK `poche_count` | fixed |
| 17 | grange range indexes were unreachable from poche | `schema index … --range`, admin `kind`, SDK helper | fixed |
| 18 | Browser clients failed CORS preflight | OPTIONS 204 + explicit methods and headers | fixed |
| 19 | REST creates returned 200 instead of resource semantics | POST now returns 201; SDK accepts 200/201 | fixed |

The goal threshold is met: **19 concrete gaps fixed and exercised by the three
compiled machin backends**.

Target: at least 10 verified fixes before this dogfood goal is complete.
