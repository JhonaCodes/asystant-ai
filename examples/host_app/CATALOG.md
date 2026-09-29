# Botánica catalog: authoring guide

The bundled catalog lives in `assets/seed/`:

- `botanica_seed.json` — `version`, the shared `reference` vocabulary and the
  `plants` list of ids. Bump `version` whenever any plant file changes; the app
  re-applies the seed on the next start and never touches plants the person
  added.
- `plants/<id>.json` — one file per plant. `id` is the common name in
  lowercase ASCII with `_` (`diente_de_leon`, `sauco`).
- `../plants/<id>.jpg` — its photo.

`test/seed_catalog_test.dart` is the gate. While writing, check your own files
with `PLANTS=id1,id2 TZ=UTC flutter test test/seed_catalog_test.dart`; without
`PLANTS` it checks the whole catalog and requires at least 100 plants.

All text the person reads is **neutral Spanish** (no voseo), in short, plain
sentences for someone who will not read much. Field names and this guide are
English.

## The three views, each with its own sources

Every plant speaks for three views and cites at least one source for each:

| View | Where it lives | Good sources |
|---|---|---|
| Botany (`botany`) | how it looks, how to recognize it, how to grow it at home, what it is confused with, where it comes from | POWO (Kew), Tropicos, national floras, botanical gardens, university extension services |
| Popular use | `indications` with `evidence: "popular"`, and `beliefs` | ethnobotanical studies of Latin America (journal articles, theses), WHO/PAHO or national traditional-medicine documents, TRAMIL |
| Science | `indications` with `wellEstablished`, `traditional` or `limited`, safety fields, `beliefs[].note` | EMA/HMPC monographs, WHO monographs, NCCIH, NIH ODS, MedlinePlus, LiverTox, Cochrane and systematic reviews on PubMed |

`sources` holds every source once:

```json
{"id": "s1", "kind": "science", "title": "…", "publisher": "EMA HMPC",
 "url": "https://…", "accessedOn": "2026-09-28"}
```

`kind` is `botany`, `popular` or `science`. Everything else cites sources by
id in its own `sources` list. Only use a source you opened and read; the url
must be `https` and reach that page. Never cite a source for something it
does not say.

## Uses

```json
{"tag": "headache", "label": "Dolor de cabeza leve", "evidence": "wellEstablished",
 "note": "Aceite de menta diluido en la frente y las sienes; solo adultos.",
 "sources": ["s1"]}
```

- `tag` must be a `symptom` or `goal` term of the vocabulary.
- `evidence`: `wellEstablished` (EMA well-established use or strong reviews),
  `traditional` (EMA/WHO traditional use), `limited` (small or inconsistent
  studies), `popular` (only popular use; cite a `popular` source). Non-popular
  uses cite a `science` source.
- A popular use can be recommended by the app, always marked as unproven and
  ranked below everything with evidence. **Only list it as a use when acting
  on it is reasonably safe**; otherwise it is a belief.

## Plants with no safe use

Some popular plants have no use that is safe to recommend (for instance, when
every popular use is internal and the plant is toxic). Such a plant has no
`indications` and no `preparations`: its `beliefs`, `easyExplanation` and
safety fields explain why, and the app only shows it. Never invent a use to
fill the file.

## Beliefs (shown, never recommended)

Popular claims that are unsafe or misleading to act on — cures cancer, causes
abortion, cleans the blood, replaces a medicine:

```json
{"claim": "Cura el cáncer", "note": "No hay estudios en personas que lo muestren y en dosis altas puede dañar los nervios.",
 "sources": ["s4", "s6"]}
```

`note` states what science knows and cites a `science` source.

## Preparations

```json
{"form": "infusion", "route": "oral", "title": "Té de menta",
 "uses": ["indigestion", "bloating"],
 "steps": [{"kind": "boilWater", "text": "Hierve agua."},
           {"kind": "pour", "text": "Échala sobre hojas de menta, frescas o secas, en una taza."},
           {"kind": "steep", "text": "Deja reposar 5 a 10 minutos."},
           {"kind": "drink", "text": "Cuela y tómalo."}],
 "warnings": ["No lo des a niños menores de 4 años."],
 "dose": "1 cucharadita de hoja seca (1,5 a 3 g) o 1 cucharada de hojas frescas por taza.",
 "frequency": "Hasta 3 tazas al día.", "maxDays": 14,
 "instructions": "The full explanation, as the source gives it, in Spanish.",
 "sources": ["s1"]}
```

- `form`: `infusion`, `decoction`, `tincture`, `topical`, `capsule`,
  `essentialOil`, `gel`, `freshPlant`. `route`: `oral`, `topical`,
  `inhalation`.
- `steps[].kind`: `buy`, `clean`, `boilWater`, `simmer`, `pour`, `steep`,
  `strain`, `cool`, `drink`, `swallow`, `dilute`, `apply`, `compress`,
  `rinse`, `inhale`, `bath`. One short sentence per step.
- `uses` are tags of this plant's uses that this preparation is for.
- Many people grow these plants: say "frescas o secas" when the fresh plant
  is used, and give home measures (cucharadita, cucharada, taza) **only when
  a source gives the amount**, with grams in parentheses. Without a sourced
  amount, write what the source says (for instance "La que indique el
  envase") — never an invented number or time.
- Pharmacy products (capsules, essential oils, tinctures, creams) are not
  made at home; say so in the steps.
- `warnings` are short, one idea each, taken from the sources.

## Safety fields

`pregnancy` and `lactation` (`acceptable`, `avoid`, `notEstablished`),
`minAgeYears`, `contraindications` (`{"kind": "condition" | "allergy", "tag",
"note"}`), `interactions` (`{"medicationClass", "severity": "avoid" |
"caution", "note"}`), `allergenGroups` and `sideEffects`. When a source is
silent, choose the conservative value (`notEstablished`, a higher minimum
age). `safetySources` lists the ids of the science sources behind these
fields.

Every source must be cited by something: a use, a preparation, the botany
section, a belief or `safetySources`. A source nothing cites is removed —
never add one only to satisfy the three-views rule. Toxic plants say so plainly in `easyExplanation`, `sideEffects` and the
warnings.

## Vocabulary

Tags come from `reference.terms` in `botanica_seed.json`. When a plant needs a
term that does not exist, propose it in the plant file (the app ignores this
key) and use it:

```json
"newTerms": [{"id": "heartburn", "label": "Acidez o ardor de estómago",
  "kind": "symptom", "synonyms": ["agruras", "ardor de estómago"]}]
```

Check first whether an existing term already covers it, including its
synonyms. Proposed terms are merged into the vocabulary before the catalog is
released, and `newTerms` is removed.

## Photo

One freely licensed photo from Wikimedia Commons (CC0, public domain, CC BY or
CC BY-SA) that shows the plant clearly, saved as `assets/plants/<id>.jpg` at
most 800 px on its longest side and about 120 KB
(`sips -Z 800 -s format jpeg -s formatOptions 62 <file>`), with its credit:

```json
{"ref": "asset://assets/plants/menta.jpg", "author": "…", "license": "CC BY-SA 4.0",
 "licenseUrl": "https://creativecommons.org/licenses/by-sa/4.0",
 "sourceUrl": "https://commons.wikimedia.org/wiki/File:…", "caption": "Hojas de menta"}
```
