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

Target: at least 10 verified fixes before this dogfood goal is complete.
