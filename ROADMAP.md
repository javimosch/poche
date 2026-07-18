# ROADMAP

## Done (v0.1.0)

- [x] Scaffold + VISION + four cli-specs surface
- [x] grange-backed store + schema/data CRUD
- [x] Auth (users/roles/grants) + single-actor HTTP serve
- [x] Realtime `/watch` long-poll
- [x] Files (blob dir + `_files` meta)
- [x] Bench 100k
- [x] docs/ + changelog-updater layout
- [x] grange `engine.src` split → `registry.src` (≤500 LOC)

## Done (follow-ups)

- [x] Schema validation on HTTP POST/PUT (`doc_from_json`)
- [x] Watch cookbook + guide semantics
- [x] MFL client SDK
- [x] GH Actions release + pages + `update` swap
- [x] Cloud tenancy OSS (`POCHE_CLOUD=1`)
- [x] File HTTP `GET /files/:id`
- [x] grange concurrency design doc
- [x] Live scenarios: bookstore / bank / car-renting

## Next

- [ ] Hosted cloud deploy + live peage merchant key
- [ ] grange mailbox actor (see grange/docs/CONCURRENCY.md)
- [ ] Compaction / cold collections via CLI
- [ ] Multi-arch release matrix
