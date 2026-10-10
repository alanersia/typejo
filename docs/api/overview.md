# Typejo API contract

**Status:** v0.1 primitive and v0.2 composite APIs are implemented and verified with Mojo 1.1.0. JSON parsing, serialization, and custom validators below describe later targets.

## Implemented in v0.1

`PrimitiveValue` stores one strict primitive input: `String`, `Int`, `Bool`, or a Mojo scalar floating-point value. `validate[T](input, constraints)` returns `ValidationResult[T]`. Use `is_ok()` to inspect success, `value()` after success, and `issues()` after failure. Validation issues have stable codes, an empty root path, and deterministic order. Invalid input is returned as issues rather than terminating the process. Call `value()` only after `is_ok()` returns true.

Constraints include inclusive `Int` bounds for integer inputs, inclusive `Float64` bounds for floating-point inputs, and minimum/maximum string length in Unicode code points. Boolean validation takes no constraints. There is no implicit coercion; non-finite floats and invalid constraint configurations are reported as issues. `Float4_e2m1fn` is decoded from its packed representation because Mojo 1.1 does not provide a CPU scalar conversion for it.

See [the runnable primitive example](../../examples/primitives.mojo) and [the primitive tests](../../tests/test_primitives.mojo). The first milestone does not include model integration, collections, optional/null handling, JSON, or serialization.

## Implemented in v0.2

`InputValue` is a flat, owned tree assembled by an application. Its root is an object; callers add object fields, array items, nulls, and `PrimitiveValue`s. `validate_model[T](input, node, unknown_fields)` checks the tree and calls `T.from_input(...)` on a `TypejoModel` adapter. The adapter constructs the concrete struct and uses `validate_field`, `validate_optional_field`, `validate_primitive_array`, and `validate_model_array` to validate its fields. Mojo 1.1 reflection can enumerate model field names for unknown-field detection, but it does not construct arbitrary model fields automatically.

Required primitive fields reject missing values and nulls. Optional primitive fields can distinguish missing from explicit null during validation; `required`, `nullable`, and `default` control those cases. Defaults are validated, and invalid defaults receive `invalid_default`. Array constraints use `min_length`/`max_length`; item errors retain integer index path segments. Nested model issues retain field and index segments. Unknown fields are rejected by default, or adapters can request ignore/preserve behavior; preservation requires `supports_extras()` and an `ExtraFields` member populated with `collect_extras[T]`. Preserved entries expose `kind()` values through the public `INPUT_NULL`, `INPUT_PRIMITIVE`, `INPUT_OBJECT`, and `INPUT_ARRAY` constants, and the copied input tree remains available for nested values.

This input tree is a caller-built validation boundary, not a JSON parser. See [the model example](../../examples/models.mojo) and [composite tests](../../tests/test_composites.mojo). Run them from the repository root with `mojo -I . examples/models.mojo` and `mojo -I . tests/test_composites.mojo`.

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
| Model declaration | A Mojo `struct` implementing `TypejoModel.from_input`. | `validate_model[T]` returns the requested struct type or issues. | The declared struct remains the success type; no dynamic field insertion. | `struct User: TypejoModel` | Implemented with an explicit adapter; automatic derive/metadata remains unproven and is a v0.3 feasibility question. |
| Field constraints | A field type plus named constraints such as length/range. | Metadata/schema input; invalid configuration is a declaration error where possible, otherwise a structured schema error. | A constraint does not widen the field's Mojo type. | `field(min_length=1)` | Illustrative only; do not assume decorators/annotations or Python `Field()` syntax. |
| `validate[T]` / `validate_model[T]` | `PrimitiveValue` for primitives; caller-built `InputValue` plus a `TypejoModel` adapter for structs. | `ValidationResult[T]` contains a typed value or ordered issues. | Strict primitive checks and typed model output; no implicit coercion. | `validate_model[User](input)` | Implemented for adapter-defined primitive fields, nested models, and arrays. JSON parsing and arbitrary reflective construction are not implemented. |
| `validate_or_raise[T]` | Same input/policy as `validate`. | `T` or a propagated Typejo/Mojo error. | Same success type as safe validation. | `validate_or_raise[User](value)` | Mojo errors can propagate and must be handled; convenience only, not the recommended untrusted-input boundary. |
| `validate_json[T]` | JSON text/bytes and parse/validation options. | A result containing `T`, or a categorized parse/validation error. | No model is exposed until both parsing and validation succeed. | `validate_json[User](source)` | JSON parser is not verified in stdlib 1.1.0; parser strategy is a v0.4 gate. |
| `to_json` / `to_json_string` | A supported typed Mojo value and serialization options. | JSON value/text result or structured serialization error. | Input is statically typed; unsupported field types are reported rather than silently dropped. | `to_json_string(user)` | JSON serializer strategy and ownership costs need a v0.5 prototype. |
| Custom field/model validators | Typed value(s), validator function, and optional error context. | Success or structured issue(s); validator failure is not an uncaught runtime exception. | Inputs are only passed after prerequisite type checks; transformations use a distinct typed contract. | `validate_with[User](user, check)` | Trait/generic callback shape must be compiler-checked; synchronous only in v1.0. |
| Error inspection | `ValidationResult[T]`. | `is_ok()`, `value()` on success, or ordered `issues()` on failure; issues include stable codes, messages, display paths, and typed path segments. | The success branch yields `T`; error data does not pretend to be a model. | `result.issues()` | Implemented; callers should check `is_ok()` before `value()`. |
| `json_schema[T]` | A model type and explicit schema dialect. | Schema value/text or an error describing unsupported features. | Describes only enforced and representable constraints. | `json_schema[User](dialect)` | v0.7 subset; custom validators may not map to JSON Schema. |

The canonical safe APIs are `validate` for primitives and `validate_model` for adapter-backed structs; `validate_json` and `to_json_string` are later targets. `validate_json` covers parsing and deserialization; a second `from_json` synonym is not proposed. The public package import is `typejo`; the API may evolve before v1.0.

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

Each validation issue contains a stable code, typed path segments, and a human-readable message. A validation result aggregates independent issues in deterministic order. Parse and serialization errors use separate categories. Expected bad input is data, not an unhandled process-level error. See [core semantics](../specifications/semantics.md).

## Required Mojo features and known limits

The implemented API relies on Mojo structs, generic parameters, traits, typed collections, and explicit error/result handling. Compile-time reflection currently enumerates fields for unknown-field checks; adapter code performs typed field access and construction. No dynamic class model, runtime monkey-patching, Python runtime, asynchronous validator, or unrestricted type erasure is assumed.
