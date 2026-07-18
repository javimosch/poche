# Benchmarks & live scenarios

Measured 2026-07-19 on the maintainer workstation.

## Bulk engine (`poche bench`)

```sh
POCHE_DB=/tmp/poche-bench ./poche bench --n 100000
```

| metric | result |
|---|---|
| n | 100_000 |
| insert | **176k docs/s** (566 ms) |
| indexed find `status=paused` limit 50 | &lt;1 ms |
| count paused | 33_334 |

## Live HTTP scenarios (`scripts/scenario.sh`)

Each scenario: schema + indexes + expose → serve → N HTTP creates → list/where → watch → typed rejection → file GET.

| scenario | n | insert_ms | docs/s (HTTP) | bad type → | watch resync@0 | file GET |
|---|---|---|---|---|---|---|
| bookstore | 400 | 5589 | 71 | **400** | 1 | ok |
| bank | 400 | 9331 | 42 | **400** | 1 | ok |
| car-renting | 400 | 5984 | 66 | **400** | 1 | ok |

HTTP docs/s is accept-loop + curl process overhead (not engine-bound). Engine throughput is the bench row above.

```sh
./scripts/scenario.sh bookstore 400
./scripts/scenario.sh bank 400
./scripts/scenario.sh carrent 400
```
