# Typejo

Typejo aims to be a standalone, type-safe, Mojo-native library for schema validation, parsing, and serialization. It takes developer-experience cues from Pydantic and Zod while following Mojo's type system and ownership model.

The v1.0 target is reliable conversion between untrusted external data and strongly typed Mojo models, with predictable validation behavior and structured errors. Typejo must work without Miduct and must not require Python at runtime.

**Implementation status:** pre-alpha. The repository currently contains only a Mojo hello-world program; the Typejo package, public API, tests, and examples have not been implemented. All documented capabilities are targets or proposals unless explicitly marked otherwise.

Start with the [documentation index](docs/README.md), [roadmap](docs/roadmap.md), [architecture](docs/architecture/overview.md), and [proposed API contract](docs/api/overview.md).

## Contributing

Issues and pull requests are welcome. For a substantial change, open an issue first so the direction can be discussed before implementation.

## License

Typejo is licensed under the [Apache License, Version 2.0](LICENSE).
