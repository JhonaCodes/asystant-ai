"""Prints one batch's plants as prompt lines: python3 batch_lines.py 13"""
import json, sys
n = int(sys.argv[1])
plan = json.load(open('/private/tmp/claude-501/-Volumes-Data/7a658dc9-84b2-46e3-b41d-4d4572e32bc4/scratchpad/batch_plan.json'))
batch = next(b for b in plan['batches'] if b['batch'] == n)
for p in batch['plants']:
    names = ', '.join(p.get('commonNames', [])[:3])
    uses = ', '.join(p.get('popularUses', [])[:4])
    safety = f" SAFETY: {p['safetyNote']}" if p.get('safetyNote') else ''
    print(f"- {p['scientificName']} — names: {names}; countries: {', '.join(p.get('countries', [])[:3])}; "
          f"popular uses seen: {uses}; lists: {', '.join(p.get('lists', []))}; science hint: {p.get('scienceHint', '')}.{safety}")
