# Typejo

Typejo aims to be a standalone, type-safe, Mojo-native library for schema validation, parsing, and serialization. It takes developer-experience cues from Pydantic and Zod while following Mojo's type system and ownership model.

The v1.0 target is reliable conversion between untrusted external data and strongly typed Mojo models, with predictable validation behavior and structured errors. Typejo must work without Miduct and must not require Python at runtime.

**Implementation status:** v0.1 primitive validation, v0.2 composite validation, v0.3 model ergonomics, and v0.4 JSON parsing/deserialization are implemented for Mojo 1.1.0. Model construction uses an explicit `TypejoModel` adapter over an `InputValue` tree. Serialization and later milestones remain planned.

The library API lives in the `typejo/` package. From the repository root, run `mojo -I . examples/primitives.mojo`, `mojo -I . examples/models.mojo`, or `mojo -I . examples/json.mojo`; run suites with `mojo -I . tests/test_primitives.mojo`, `mojo -I . tests/test_composites.mojo`, and `mojo -I . tests/test_json.mojo`. `examples/` contains application entry points; `typejo/__init__.mojo` is the public package entry point. Start with the [documentation index](docs/README.md), [roadmap](docs/roadmap.md), [architecture](docs/architecture/overview.md), and [API contract](docs/api/overview.md).

## Contributing

Issues and pull requests are welcome. For a substantial change, open an issue first so the direction can be discussed before implementation.

## License

Typejo is licensed under the [Apache License, Version 2.0](LICENSE).
