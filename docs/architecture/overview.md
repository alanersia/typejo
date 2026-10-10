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

## Proposed processing flow

1. A format adapter parses bytes/text into a format value tree. Syntax errors stay format errors.
2. The validator checks types, presence, nullability, and constraints, producing either a typed model or validation issues.
3. Optional transformations run only when configured and return a declared output type.
4. A serializer maps a validated typed model to a format value tree and then to output text/bytes.

The format value tree and parser are proposed components, not implemented code. The v0.4 feasibility decision must settle whether JSON parsing is owned by Typejo or supplied by a standalone Mojo dependency.

## Model mapping decision

The preferred target is one Mojo struct definition as the source of field types, with field constraints expressed as metadata or a reusable mapping that does not duplicate types. Mojo 1.1.0 has compile-time reflection APIs for struct field information, but the full workflow from metadata to safe field access, nested validation, and construction has not been demonstrated in this repository.

v0.3 is therefore a feasibility milestone, not a promise of automatic derive. If deriving is not viable, use a documented explicit model trait/adapter as the fallback. It must map each field once and delegate primitive/composite rules to reusable Typejo validators; it must not ask users to write a second full validator by hand.

## Compatibility and status

The v0.1 primitive API and tests are verified with Mojo 1.1.0. The repository has no package manifest or compatibility policy, and model integration remains proposed. See [Mojo compatibility](mojo-compatibility.md) and the [roadmap](../roadmap.md).
