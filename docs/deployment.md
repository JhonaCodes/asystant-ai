# Gateway deployment has moved

The Rust service is maintained separately in
[JhonaCodes/asystant-api](https://github.com/JhonaCodes/asystant-api).
It uses SQLite with a persistent `/data` volume and requires no PostgreSQL service.

Follow its [Dokploy deployment guide](https://github.com/JhonaCodes/asystant-api/blob/main/docs/deployment.md)
and [API contract](https://github.com/JhonaCodes/asystant-api/blob/main/openapi.yaml).
The Flutter SDK protocol is unchanged; tools still run in the host application.
Historical verification reports describe earlier PostgreSQL releases.
