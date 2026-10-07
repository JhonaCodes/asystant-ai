# Catalog work in progress

Material to resume growing the catalog from 120 to 1000 plants. Nothing here
is bundled with the app (only `assets/` is).

- `plant_candidates.json` — 1003 candidate species from Latin American
  ethnobotanical surveys, with the lists they come from and science hints.
- `batch_plan.json` — batches 13 to 100 (10 plants each, 880 plants) and a
  reserve of 57 candidates. Batches 11 and 12 are done.
- `plants/`, `photos/` — plant files started but not yet verified or merged
  (batch 14 stopped after `sauce_blanco`).
- `consolidate_catalog.py` — merges proposed vocabulary terms, lists finished
  plants in the seed, bumps its version and regenerates the photo credits.
  Paths inside point to this repo; adjust `ROOT` if it moves.
- `batch_lines.py` — prints one batch's plants for a research prompt; update
  the plan path inside it to this folder before use.

Every new plant still goes through research, verification and
`test/seed_catalog_test.dart`, as described in `CATALOG.md`.
