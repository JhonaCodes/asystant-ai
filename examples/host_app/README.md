# Botánica — host example for asystant_ai

A local-first botanical medicine app. A person tells the assistant how they
feel and what they want to achieve; the assistant asks the questions, records
the consultation, and recommends plants from the bundled catalog with how to
take them and a photo to recognize them. Recommendations come from data only:
a deterministic engine matches symptom and goal tags against the catalog and
excludes plants that are unsafe for the person.

The assistant lives in one integration, `lib/src/integrations/ai/`, built
with `part`/`part of`: the rest of the app imports `ai.dart` and uses a single
widget, `AiAssistantButton`.

```text
lib/
├── main.dart          Log.init → InfraService.open() → runApp
└── src/               The app (enterprise architecture)
    ├── core/          navigation, network (ApiImpl + LocalApi), services
    ├── integrations/
    │   ├── ai/        The assistant: workspace (AsystantAI + prompts),
    │   │              tools, connection; exports AiAssistantButton only
    │   └── device · local_db · files · links
    ├── modules/       reference · plant · profile · assessment · recommendation · home
    └── shared/        theme, strings (neutral Spanish), extensions, widgets
```

## The boundary

- **The app has no intake forms.** The assistant collects the person's
  history, symptoms, goals and photos and saves them through the public
  methods of the view models (`ProfileService.notifier.addMedication`,
  `AssessmentService.notifier.addSymptom`, `PlantService.notifier.addPersonPlant`,
  `RecommendationService.notifier.recommend`, ...). The UI shows what was
  recorded and lets the person delete it.
- **Tools call view models, never repositories or the database.** They live
  in `lib/src/integrations/ai/tools/`, registered in the assistant.

## Data: local today, remote tomorrow

Repositories talk to an `ApiImpl` with REST-like paths (`/plants`,
`/profile/me`, `/assessments`, `/reference/current`, `/files`) and a
`{"data": ...}` envelope. `LocalApi` answers them on the device with
`flutter_local_db` (JSON documents) and a file vault for photos
(`local://photos/<id>.jpg`). To move to a server, implement `ApiImpl` over
HTTP with the same paths and replace one line in
`lib/src/core/services/infra_service.dart`.

The seed (`assets/seed/botanica_seed.json` plus one file per plant in
`assets/seed/plants/`) is applied once per version and never overwrites plants
the person added. Plant photos come from Wikimedia Commons; see
`assets/plants/CREDITS.md`.

## The catalog

100 medicinal plants common in Latin American gardens and markets. Each one
speaks for three views, every statement citing its sources: botany (how it
looks, how to grow it, what it is confused with), popular use, and science
(evidence level and safety). Popular uses can be recommended, always marked
as unproven and ranked below everything with evidence; popular beliefs that
are unsafe to act on are shown but never recommended, and six plants have no
safe use at all. `CATALOG.md` is the authoring guide and
`test/seed_catalog_test.dart` enforces its rules.

## Safety

- Warning signs (chest pain, breathing difficulty, sudden severe headache,
  and others, defined as data) stop the recommendation and advise seeing a
  doctor.
- Missing age, pregnancy or lactation answers stop it too: the assistant must
  ask first.
- Plants are excluded for age, pregnancy, lactation, conditions, allergies and
  medicines to avoid; plants the person added are shown but never
  recommended automatically.
- Every recommendation shows a short disclaimer. This is guidance based on
  public information, not medical care.

## Run

```sh
flutter pub get
cd examples/host_app
TZ=UTC flutter test test/recommendation_engine_test.dart
flutter run -d <device> --dart-define-from-file=.env
```

`.env` holds `OPENROUTER_API_KEY` (ignored by Git) for local tests; without it
the assistant opens but cannot reach the model.

## Assistant tools

| Tool | What it does | Asks first |
|---|---|---|
| `list_plants` | Shows the catalog (or the plants matching a name) as a card gallery in the chat, through the gen-ui card and `cardContentBuilder` | No, read-only |
| `save_profile` | Saves what the person says about themselves (age, sex, pregnancy, lactation, conditions, allergies), matched to the vocabulary | No: saved as said, shown in a card, erasable in Profile |
| `add_medication` | Saves a medicine and its class, so the engine can leave out interacting plants | No, same as above |
| `recommend_plants` | Records symptoms and goals in a consultation and runs the recommendation engine; the card shows the plants with how to take them | No: the engine decides from data and the saved profile |

What the assistant knows about the person travels with every answer: the
app returns it from `contextPrompts()`, which the library reads before each
model call, so a fact saved by a tool is already known in the next reply.

There is no sample data: the profile and the consultations only hold what
the person tells the assistant.
