# Typejo API contract

**Status:** v0.1 primitive, v0.2 composite, v0.3 model ergonomics, and v0.4 JSON parsing/deserialization APIs are implemented and verified with Mojo 1.1.0. Serialization and custom validators below remain later targets.

## Implemented in v0.1

`PrimitiveValue` stores one strict primitive input: `String`, `Int`, `Bool`, or a Mojo scalar floating-point value. `validate[T](input, constraints)` returns `ValidationResult[T]`. Use `is_ok()` to inspect success, `value()` after success, `value_or(default)` to get the value or a fallback, and `issues()` after failure. `value_or` does not discard issues, so adapters can use a temporary value while collecting errors; return no model when issues remain. Validation issues have stable codes, an empty root path, and deterministic order. Invalid input is returned as issues rather than terminating the process.

Constraints include inclusive `Int` bounds for integer inputs, inclusive `Float64` bounds for floating-point inputs, and minimum/maximum string length in Unicode code points. Boolean validation takes no constraints. There is no implicit coercion; non-finite floats and invalid constraint configurations are reported as issues. `Float4_e2m1fn` is decoded from its packed representation because Mojo 1.1 does not provide a CPU scalar conversion for it.

See [the runnable primitive example](../../examples/primitives.mojo) and [the primitive tests](../../tests/test_primitives.mojo). The first milestone does not include model integration, collections, optional/null handling, JSON, or serialization.

## Implemented in v0.2

`InputValue` is a flat, owned tree assembled by an application. Its root is an object; callers add object fields, array items, nulls, and `PrimitiveValue`s. `validate_model[T](input, node, unknown_fields)` checks the tree and calls `T.from_input(...)` on a `TypejoModel` adapter. The adapter constructs the concrete struct and uses `validate_field`, `validate_optional_field`, `validate_primitive_array`, and `validate_model_array` to validate its fields. Mojo 1.1 reflection can enumerate model field names for unknown-field detection, but it does not construct arbitrary model fields automatically.

Required primitive fields reject missing values and nulls. Optional primitive fields can distinguish missing from explicit null during validation; `required`, `nullable`, and `default` control those cases. Defaults are validated, and invalid defaults receive `invalid_default`. Array constraints use `min_length`/`max_length`; item errors retain integer index path segments. Nested model issues retain field and index segments. Unknown fields are rejected by default, or adapters can request ignore/preserve behavior; preservation requires `supports_extras()` and an `ExtraFields` member populated with `collect_extras[T]`. Preserved entries expose `kind()` values through the public `INPUT_NULL`, `INPUT_PRIMITIVE`, `INPUT_OBJECT`, and `INPUT_ARRAY` constants, and the copied input tree remains available for nested values.

This input tree is a caller-built validation boundary, not a JSON parser. See [the model example](../../examples/models.mojo) and [composite tests](../../tests/test_composites.mojo). Run them from the repository root with `mojo -I . examples/models.mojo` and `mojo -I . tests/test_composites.mojo`.

## Implemented in v0.4

`JsonOptions` configures parsing and model validation. Defaults are 1,048,576 input bytes, nesting depth 128, 10,000 items per collection, and 100 returned issues; `coerce_numeric_strings` defaults to `false`. `parse_json(source, options)` returns an owned `InputValue` tree for any JSON root value. The parser rejects malformed syntax and duplicate object keys, and parse issues include a stable code plus byte offset and 1-based line/column.

`validate_json[T](source, options, unknown_fields)` parses then calls the model's `TypejoModel` adapter. Syntax failures retain their source location; schema failures retain field/index paths. It returns a typed model only when validation succeeds. JSON numeric tokens retain their original spelling internally for exact integer conversion; integer destinations reject fractions and out-of-range values. Float destinations use Float64 parsing and report non-finite/out-of-range values. Strict mode is the default; with `coerce_numeric_strings=True`, strings matching JSON number syntax may convert to `Int` or `Float64`.

The `max_issues` setting caps the issues returned from `validate_json`; model adapters may aggregate their issues before this final cap. Serialization is not implemented. See the [JSON format contract](../specifications/data-formats.md) and [JSON integration tests](../../tests/test_json.mojo).

## Later API targets

The remainder of this page describes v1.0 design targets and does not imply implementation.

## API design rules

- Use lower `snake_case` for functions and `PascalCase` for types, following Mojo conventions.
- Make safe validation return a typed result rather than raising for ordinary invalid input.
- Keep format syntax errors separate from schema validation errors.
- Make strict behavior the default; coercion must be explicit.
- Return the requested concrete Mojo model type on success.
- Keep field names/types in the model definition once; metadata and reusable validators add rules without a second full schema copy.
- Keep model construction and serialization within Mojo value ownership/lifetime rules.

## API surface proposal

| API | Purpose and input | Output and error behavior | Type-safety guarantee | Example shape (illustrative) | Limitations and required Mojo features |
|---|---|---|---|---|---|
| Model declaration | A Mojo `struct` implementing `TypejoModel.from_input`. | `validate_model[T]` returns the requested struct type or issues. | The declared struct remains the success type; no dynamic field insertion. | `struct User: TypejoModel` | Implemented with an explicit adapter; automatic derive/metadata remains unsupported because tested reflection does not prove safe arbitrary construction. |
| Field constraints | A field type plus named constraints such as length/range. | Metadata/schema input; invalid configuration is a declaration error where possible, otherwise a structured schema error. | A constraint does not widen the field's Mojo type. | `field(min_length=1)` | Illustrative only; do not assume decorators/annotations or Python `Field()` syntax. |
| `validate[T]` / `validate_model[T]` | `PrimitiveValue` for primitives; caller-built `InputValue` plus a `TypejoModel` adapter for structs. | `ValidationResult[T]` contains a typed value or ordered issues. | Strict primitive checks and typed model output; no implicit coercion. | `validate_model[User](input)` | Implemented for adapter-defined primitive fields, nested models, and arrays. Arbitrary reflective construction is not implemented. |
| `validate_or_raise[T]` | Same input/policy as `validate`. | `T` or a propagated Typejo/Mojo error. | Same success type as safe validation. | `validate_or_raise[User](value)` | Mojo errors can propagate and must be handled; convenience only, not the recommended untrusted-input boundary. |
| `parse_json` / `validate_json[T]` | JSON text and `JsonOptions`; model validation also takes unknown-field policy. | `InputValue` tree or typed model, otherwise categorized parse/validation issues. | No model is exposed until parsing and adapter validation succeed. | `validate_json[User](source)` | Implemented in v0.4; duplicate keys are rejected; serialization is not included. |
| `to_json` / `to_json_string` | A supported typed Mojo value and serialization options. | JSON value/text result or structured serialization error. | Input is statically typed; unsupported field types are reported rather than silently dropped. | `to_json_string(user)` | JSON serializer strategy and ownership costs need a v0.5 prototype. |
| Custom field/model validators | Typed value(s), validator function, and optional error context. | Success or structured issue(s); validator failure is not an uncaught runtime exception. | Inputs are only passed after prerequisite type checks; transformations use a distinct typed contract. | `validate_with[User](user, check)` | Trait/generic callback shape must be compiler-checked; synchronous only in v1.0. |
| Error inspection | `ValidationResult[T]`. | `is_ok()`, `value()` on success, `value_or(default)` for a fallback, or ordered `issues()`; issues include stable codes, messages, display paths, and typed path segments. | The success branch yields `T`; error data does not pretend to be a model. | `result.value_or(default)` | Implemented; `value()` requires success, while `value_or` leaves failure issues available. |
| `json_schema[T]` | A model type and explicit schema dialect. | Schema value/text or an error describing unsupported features. | Describes only enforced and representable constraints. | `json_schema[User](dialect)` | v0.7 subset; custom validators may not map to JSON Schema. |

The canonical safe APIs are `validate` for primitives, `validate_model` for caller-built trees, and `validate_json` for JSON text. `validate_json` covers parsing and deserialization; a second `from_json` synonym is not proposed. The public package import is `typejo`; the API may evolve before v1.0.

## Illustrative usage (not compilable API)

```text
# Illustrative only: names and syntax are proposals, not tested Mojo code.
result = typejo.validate_json[User](source)

if result.is_ok():
    user = result.value()        # statically typed User
else:
    for issue in result.errors():
        print(issue.code, issue.path, issue.message)

encoded = typejo.to_json_string(user)
```

## Error contract

Each validation issue contains a stable code, typed path segments, and a human-readable message. Parser issues additionally expose `source_offset`, `source_line`, and `source_column`; non-parser issues use `-1` for these fields. A validation result aggregates independent issues in deterministic order. Parse and serialization errors use separate categories. Expected bad input is data, not an unhandled process-level error. See [core semantics](../specifications/semantics.md).

## Required Mojo features and known limits

The implemented API relies on Mojo structs, generic parameters, traits, typed collections, and explicit error/result handling. Compile-time reflection currently enumerates fields for unknown-field checks; adapter code performs typed field access and construction. No dynamic class model, runtime monkey-patching, Python runtime, asynchronous validator, or unrestricted type erasure is assumed.
