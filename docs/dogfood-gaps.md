# Dogfood gaps — real backend examples

Goal: build three machin backends in `examples/` and turn every real integration
friction into a tested poche improvement.

| # | Found while building | Fix | Status |
|---|---|---|---|
| 1 | Apps could not bootstrap schemas/indexes/exposure over HTTP | Admin bootstrap API + SDK helpers | fixed |
| 2 | Social profiles/posts could be created without identity/content | Required fields via `field:type!`, enforced in CLI and HTTP creates | fixed |
| 3 | A typo in an app schema silently became an unusable runtime type | Strict schema syntax/type/duplicate validation | fixed |

Target: at least 10 verified fixes before this dogfood goal is complete.
