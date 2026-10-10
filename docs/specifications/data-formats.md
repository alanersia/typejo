# Parsing, serialization, and schema formats

**Status:** proposed contract for v0.4, v0.5, and v0.7. No format support exists in the repository today.

## JSON parsing and model validation

Keep two stages and error families distinct:

1. **Syntax parsing** converts JSON text/bytes into JSON values. Invalid tokens, escapes, delimiters, encoding, or truncated input produce a parse error with a source location when available.
2. **Schema validation/deserialization** converts a parsed JSON value to a requested Mojo type. Missing fields, wrong types, constraints, and unknown fields produce validation issues with typed model paths.

A convenience API may compose these stages, but its error must retain the category and details of the failing stage. Safe entry points return errors instead of allowing malformed or untrusted input to terminate the application.

JSON numbers need explicit handling: integer conversion must preserve range and reject fractions; floating-point conversion must document precision and non-finite behavior. JSON `null` follows the separate nullability rules in [core semantics](semantics.md).

The audited Mojo 1.1.0 standard-library index does not list a JSON package. Typejo must choose between owning a small parser/serializer and depending on a standalone Mojo library. Before v0.4, record that decision with dependency, license, maintenance, ownership, and version-compatibility consequences. Typejo must not depend on Python or Miduct to satisfy the format contract.

## Serialization

Serialization accepts a validated typed value and emits only supported JSON values. It is not validation of untrusted input and is not deserialization. The v1.0 contract must define:

- Whether absent `Optional` fields are omitted or emitted as `null` (default target: omit absent fields).
- Whether explicit nullable `null` values are emitted (default target: emit `null`).
- Whether fields equal to defaults are included (default target: include them unless explicitly excluded).
- Inclusion/exclusion by field name and how nested rules compose.
- Escaping, Unicode, number formatting, and deterministic output. Object keys are emitted in model field declaration order.
- Errors for unsupported field types, values outside JSON's data model, and non-finite floats.

Round-trip equality is required only for values in the documented supported subset and only where the chosen JSON numeric/string representation preserves the value. The contract does not promise preservation of whitespace, original number spelling, input object key order, or unknown fields unless the model policy explicitly stores them.

## JSON Schema

JSON Schema generation is a v0.7 target for an explicit dialect and a documented supported subset. Generated schema must describe the behavior Typejo enforces. Unsupported/custom validators must not be represented as if JSON Schema can express them; the generator must report the gap or fail clearly. A schema export is an integration artifact, not a runtime validator and not an OpenAPI server feature.
