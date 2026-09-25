# Reference-system findings

The initial design was informed by the existing Aula-AI experience described by the project owner and a read-only review of the authorized reference paths. No reference application was modified or copied into this distribution.

The operations panel manages plans, budgets and credentials. The backend associates AI access with the current product session and tracks usage limits. The provided standalone mobile assistant directory was empty at inspection time.

This implementation consolidates the reusable contracts while keeping product tools local. It uses a gateway-owned provider key and short-lived opaque client credentials rather than distributing provider child keys. Each product implements its own session-to-ticket bridge. Reference behavior is architectural context, not proof that a live product has already integrated this SDK.
