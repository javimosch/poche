# Watch cookbook (agents)

`GET /watch?coll=<name>&since=<n>&timeout=<sec>` long-polls for mutations on an **exposed** collection. Auth: `Authorization: Bearer <token>`.

## Semantics

| Field | Meaning |
|---|---|
| `seq` | Monotonic counter for this collection in **this process lifetime** (seeded from `now_ms` on open). |
| `changes` | Array of `{seq,op,id}` since your watermark (`op` = `put` \| `del`). |
| `resync` | `1` if your `since` is behind the ring floor or ahead of `seq` — **re-list the collection**, then continue from returned `seq`. |

### Why `since=0` always resyncs

`seq_base` starts near `now_ms()`, so `0 < floor`. That is intentional: agents must not assume history across restarts. First call:

```sh
curl -sH "Authorization: Bearer $TOK" \
  "http://127.0.0.1:7700/watch?coll=articles&since=0&timeout=1"
# → {"ok":true,"data":{"seq":…,"resync":1,"changes":[]}}
```

Then either `GET /api/articles` (full snapshot) or keep polling with `since=seq`.

## Agent loop

```
seq := 0
loop:
  r := GET /watch?coll=X&since=seq&timeout=25
  if r.data.resync == 1:
      snapshot := GET /api/X
      apply_snapshot(snapshot)
  else:
      for c in r.data.changes: apply(c)
  seq := r.data.seq
```

Ring holds ~200–400 recent ops; slow consumers get `resync=1` (honest, not silent drop).
