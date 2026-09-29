# Model experience and verification

The project owner reports excellent practical results and low operating cost with
GPT-OSS 20B and GPT-OSS 120B in related application assistants. This is owner-reported
experience, not a controlled benchmark of this SDK release.

The OpenRouter model identifiers are `openai/gpt-oss-20b` and
`openai/gpt-oss-120b`. Provider prices vary and can change; consult the official
[20B model page](https://openrouter.ai/openai/gpt-oss-20b) and
[120B model page](https://openrouter.ai/openai/gpt-oss-120b) before setting budgets
in asystant-api. A company's allowed models reach the app as the credential's
`allowed_models`; the chat offers the host's `AsystantModelOption`s restricted to
them, and the first permitted one is the default.

Local tests cover tool argument validation, approvals, cancellation, credential
refresh, model restriction and chart rendering, with recorded HTTP responses. This
repository does not claim a live benchmark for either model; verify the chosen
models with real keys issued through asystant-api before production rollout. Never
commit a key or compile one into a release build.
