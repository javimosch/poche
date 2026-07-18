<h1 align="center">poche</h1>

<p align="center">
  <b>Agent-first headless CMS — one machin binary, grange underneath, no UI.</b><br>
  Collections · schemas · RBAC · REST · realtime <code>/watch</code> · files.<br>
  Built for agents ([cli-specs](https://cli-specs.intrane.fr/)).
</p>

```sh
./build.sh                         # needs machin
export POCHE_DB=./poche.data
./poche init                       # → admin_token
./poche schema define articles title:string views:int published:bool
./poche data create articles title=Hi views=1 published=true
./poche role add editor
./poche grant editor articles read,create,update
./poche user add bob editor        # → bearer token
./poche schema expose articles read,create,update
./poche serve 7700
```

```sh
curl -H "Authorization: Bearer $TOK" http://127.0.0.1:7700/api/articles
curl -H "Authorization: Bearer $TOK" 'http://127.0.0.1:7700/watch?coll=articles&since=0&timeout=25'
```

## Why poche

| Pillar | Meaning |
|---|---|
| **CMS, not SQL** | schemas + documents + grants — PocketBase-shaped, headless |
| **Agent-native** | JSON stdout, typed stderr errors, exit 80–119, `guide` / `help-json` / `feedback` / `update` |
| **grange storage** | crash-safe document DB; faster than SQLite on indexed workloads (bench 100k) |
| **Realtime** | long-poll `/watch` over grange's change ring |
| **No UI** | CLI + HTTP only; docs site for humans |

## Bench (100k docs)

```sh
POCHE_DB=/tmp/poche-bench ./poche bench --n 100000
```

Typical on a laptop: ~180k docs/s bulk insert with 2 indexes; indexed find/count in &lt;1 ms.

## Agent contract

- stdout = `{"ok":true,"version":"0.1.0","data":…}`
- stderr = `{"ok":false,"error":{code,type,message,…}}`
- exit: `0` · `80–89` input · `90–99` resource · `100–109` integration · `110–119` internal
- `poche guide` · `poche help-json` · `poche feedback "…"` · `poche update`

## Stack

poche (CMS) → [grange](https://github.com/javimosch/grange) (engine) → [machin](https://github.com/javimosch/machin)

See [`VISION.md`](VISION.md) · [`ROADMAP.md`](ROADMAP.md) · [docs](docs/index.html)

## License

MIT
