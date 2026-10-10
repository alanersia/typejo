# Typejo

Typejo aims to be a standalone, type-safe, Mojo-native library for schema validation, parsing, and serialization. It takes developer-experience cues from Pydantic and Zod while following Mojo's type system and ownership model.

The v1.0 target is reliable conversion between untrusted external data and strongly typed Mojo models, with predictable validation behavior and structured errors. Typejo must work without Miduct and must not require Python at runtime.

**Implementation status:** v0.1 primitive validation is implemented and verified with Mojo 1.1.0. Model integration, collections, JSON parsing, and serialization remain later milestones.

The library API lives in the `typejo/` package. From the repository root, run the app example with `mojo -I . examples/primitives.mojo` and the test suite with `mojo -I . tests/test_primitives.mojo`. `examples/primitives.mojo` is the application entry point; `typejo/__init__.mojo` is the public package entry point. Start with the [documentation index](docs/README.md), [roadmap](docs/roadmap.md), [architecture](docs/architecture/overview.md), and [API contract](docs/api/overview.md).

## Contributing

Issues and pull requests are welcome. For a substantial change, open an issue first so the direction can be discussed before implementation.

## License

Typejo is licensed under the [Apache License, Version 2.0](LICENSE).
