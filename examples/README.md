# poche dogfood backends

Three compiled machin applications use poche as their complete persistence/API
backend. They are intentionally domain backends, not toy CRUD snippets.

| App | Workflows | poche capabilities exercised |
|---|---|---|
| `twitter-social-media` | profiles, posts, follows, likes, timeline | required/unique fields, server timestamps, indexes |
| `amazon-marketplace` | sellers, customers, catalog, stock-safe orders | refs, numeric bounds, CAS, increment compensation |
| `car-renting` | fleet, customers, interval reservations, cancellation | compound ranges, pagination totals, numeric sort |

## Run all

```sh
./build.sh
./examples/test.sh
```

Each smoke test:

1. creates an isolated `POCHE_DB`;
2. starts the real poche HTTP actor;
3. bootstraps schemas/indexes/exposure through the machin SDK;
4. executes domain workflows;
5. verifies invariants and failure paths;
6. destroys its temporary database.

## Architecture

```text
domain binary (pure MFL)
    │ sdk/machin/poche_client.src
    ▼
poche HTTP API
    │ schemas · constraints · RBAC · mutations · query · watch
    ▼
grange embedded engine
```

The integration findings and fixes are tracked in
[`docs/dogfood-gaps.md`](../docs/dogfood-gaps.md).
