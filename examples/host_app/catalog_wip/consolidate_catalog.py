"""Merge proposed vocabulary terms and list finished plants in the seed.

Usage: python3 consolidate_catalog.py [--apply] id1 id2 ...
Without --apply it only reports what it would do.
"""
import json
import sys
from pathlib import Path

ROOT = Path('/Volumes/Data/Private/Projects/PrivateProjects/Asistant-AI/examples/host_app')
SEED = ROOT / 'assets/seed/botanica_seed.json'
PLANTS = ROOT / 'assets/seed/plants'
CREDITS = ROOT / 'assets/plants/CREDITS.md'

apply = '--apply' in sys.argv
ids = [arg for arg in sys.argv[1:] if not arg.startswith('--')]

seed = json.loads(SEED.read_text())
terms = seed['reference']['terms']
known = {term['id']: term for term in terms}
problems = []
added = []

for plant_id in ids:
    path = PLANTS / f'{plant_id}.json'
    plant = json.loads(path.read_text())
    for term in plant.get('newTerms', []):
        existing = known.get(term['id'])
        if existing is None:
            known[term['id']] = term
            terms.append(term)
            added.append((plant_id, term['id'], term['kind'], term['label']))
        elif existing['kind'] != term['kind']:
            problems.append(
                f"{plant_id}: {term['id']} is {term['kind']} here but "
                f"{existing['kind']} in the vocabulary")
        else:
            merged = sorted(set(existing.get('synonyms', [])) | set(term.get('synonyms', [])))
            existing['synonyms'] = merged
    if apply and 'newTerms' in plant:
        del plant['newTerms']
        path.write_text(json.dumps(plant, ensure_ascii=False, indent=2) + '\n')
    if plant_id not in seed['plants']:
        seed['plants'].append(plant_id)

for plant_id, term_id, kind, label in added:
    print(f'+ {kind:15} {term_id:30} {label}   (from {plant_id})')
for problem in problems:
    print('! ' + problem)

if apply and not problems:
    seed['version'] += 1
    SEED.write_text(json.dumps(seed, ensure_ascii=False, indent=2) + '\n')
    lines = ['# Plant photo credits', '',
             'Photos from Wikimedia Commons, used under the licenses listed.', '']
    for plant_id in seed['plants']:
        plant = json.loads((PLANTS / f'{plant_id}.json').read_text())
        for photo in plant.get('photos', []):
            file = photo['ref'].rsplit('/', 1)[-1]
            lines.append(
                f"- `{file}` — {plant['commonName']}: {photo['author']}, "
                f"[{photo['license']}]({photo['licenseUrl']}), "
                f"[source]({photo['sourceUrl']})")
    CREDITS.write_text('\n'.join(lines) + '\n')
    print(f"applied: seed v{seed['version']}, {len(seed['plants'])} plants, "
          f"{len(terms)} terms")
elif problems:
    print('not applied: resolve the problems first')
