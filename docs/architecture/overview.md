# Architecture overview

## Product boundary

Typejo is a standalone Mojo library that converts untrusted external data into validated, strongly typed values and serializes supported typed values back to external formats. It owns validation semantics, structured errors, and its format adapters.

Typejo is not an ORM, database driver, HTTP framework, package manager, or dependency resolver. It has no dependency on Miduct. An integration may depend on Typejo; Typejo never depends on the integration.

## Product principles

- Treat the Mojo type system and value/ownership model as design inputs, not syntax to imitate from Python or TypeScript.
- Make strict behavior predictable; every coercion is explicit and documented.
- Keep errors structured and safe to handle in application code.
- Prefer compile-time specialization when supported and measured, while retaining understandable code and bounded compile-time cost.
- Use no Python runtime dependency.
- Do not claim an API or feature is implemented until it exists and is checked against the supported compiler.

## Current and proposed processing flow

1. A format adapter parses bytes/text into a format value tree. Syntax errors stay format errors.
2. The validator checks types, presence, nullability, and constraints, producing either a typed model or validation issues.
3. Optional transformations run only when configured and return a declared output type.
4. A serializer maps a validated typed model to a format value tree and then to output text/bytes.

The v0.2 `InputValue` tree is implemented and applications can build it directly. v0.4 adds a Typejo-owned JSON parser that builds the same tree, preserving number lexemes for exact integer checks. `parse_json` exposes the parsed tree, while `validate_json[T]` composes parsing with the explicit model adapter and returns no model on failure.

## Model mapping decision

The v0.2 path uses a `TypejoModel` adapter on each Mojo struct. The adapter reads fields from `InputValue`, calls reusable Typejo field/list/nested validators, and constructs the typed result. Mojo 1.1.0 compile-time reflection enumerates field names for default unknown-field rejection; typed field access and construction stay in the adapter.

v0.3 is an ergonomics and feasibility milestone, not a promise of automatic derive. It can reduce adapter boilerplate only if the compiler supports safe field access and construction. The tested explicit adapter remains the working route.

## Compatibility and status

The v0.1 through v0.4 APIs and tests are verified with Mojo 1.1.0. The repository has no package manifest or compatibility policy; automatic model derivation remains unsupported. See [Mojo compatibility](mojo-compatibility.md) and the [roadmap](../roadmap.md).
