# Parsing, serialization, and schema formats

**Status:** JSON parsing and deserialization are implemented in v0.4. JSON serialization remains a v0.5 target and JSON Schema remains a v0.7 target.

## JSON parsing and model validation

The implemented API keeps two stages and error families distinct:

1. **Syntax parsing** converts JSON text/bytes into JSON values. Invalid tokens, escapes, delimiters, encoding, or truncated input produce a parse error with a source location when available.
2. **Schema validation/deserialization** converts a parsed JSON value to a requested Mojo type. Missing fields, wrong types, constraints, and unknown fields produce validation issues with typed model paths.

A convenience API may compose these stages, but its error must retain the category and details of the failing stage. Safe entry points return errors instead of allowing malformed or untrusted input to terminate the application.

`parse_json(source, options)` returns an owned `InputValue` tree and `validate_json[T](source, options, unknown_fields)` composes parsing with the model adapter. Defaults in `JsonOptions` are a 1 MiB input limit, depth 128, 10,000 items per collection, and 100 returned issues. Numeric-string coercion is off by default. Duplicate object keys are rejected because the `InputValue` object representation uses unique field names. The issue cap applies to the final `validate_json` result, after adapters return.

JSON integer conversion preserves the source number lexeme, rejects fractional values for integer fields, and checks destination range exactly. Float conversion uses Float64 parsing; values that overflow to non-finite numbers are rejected, and ordinary precision follows Float64. Optional coercion accepts JSON-number strings only for `Int` and `Float64`. JSON `null` follows the separate nullability rules in [core semantics](semantics.md). The parser is owned by Typejo and adds no runtime dependency; Mojo 1.1.0 did not provide a verified standard-library JSON API. Typejo does not depend on Python or Miduct.

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
