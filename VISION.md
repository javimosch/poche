# poche — Vision

## North star

> **An agent-first headless CMS in one static machin binary, backed by grange.**
>
> PocketBase-shaped surface (collections, auth, rules, realtime, files) — no Admin UI.
> Agents drive it via JSON CLI + HTTP. Apps (especially MFL) consume the same API.

## Who it's for

Agent builders and machin app authors who need a content/data backend without Node,
without a GUI, and without SQLite's indexed-query tax — grange underneath, CMS on top.

## Wedge → moat

- **Wedge (OSS):** one binary, `init → schema → data → grant → serve`, 100k-doc bench,
  realtime `/watch`, four [cli-specs](https://cli-specs.intrane.fr/).
- **Moat (cloud, later):** hosted multi-tenant poche (backups, domains, quotas, billing).
  Storage engine stays grange; poche sells the CMS + ops layer.

## Non-goals

- No Admin UI (landing + docs site only).
- No relation to machin-cms (separate product, separate stack).
- No multi-SQL backends in v0 — grange only.

## Stack

| Layer | Role |
|---|---|
| **poche** | schemas, validation, RBAC, REST, realtime fanout, files, cli-specs |
| **grange** | crash-safe document store, indexes, change feed (`/watch`) |

## North-star metric

Weekly active agents completing `schema → data → serve → watch` against a real collection.
