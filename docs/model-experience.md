# Model experience and verification

The project owner reports excellent practical results and low operating cost with
GPT-OSS 20B and GPT-OSS 120B in related application assistants. This is owner-reported
experience, not a controlled benchmark of this SDK release.

The OpenRouter model identifiers are `openai/gpt-oss-20b` and
`openai/gpt-oss-120b`. Provider prices vary and can change; consult the official
[20B model page](https://openrouter.ai/openai/gpt-oss-20b) and
[120B model page](https://openrouter.ai/openai/gpt-oss-120b) before setting gateway
price ceilings. The server selects the allowed/default model per product, tenant
or user; the application does not need to expose a model picker.

Local tests cover tool argument validation, approvals, cancellation, session renewal,
model assignment and chart rendering. A previous live OpenRouter attempt returned
HTTP 401, so this repository does not claim a successful live benchmark for either
model. Supply a valid server-side provider key and run the opt-in live gateway test
before production rollout. Never commit that key or put it in Flutter configuration.
