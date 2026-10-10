# Core validation semantics

**Status:** proposed v1.0 contract. None of these behaviors are implemented yet. Changes require updating the API contract, roadmap, comparison page, and tests together.

## Input states and fields

For an object field, the input state is one of: **missing**, **null**, **present and valid**, or **present and invalid**. Applying a default is an output state and must not erase which input state caused it in errors or validator context.

| Field declaration intent | Missing input | Explicit `null` | Valid value | Invalid value |
|---|---|---|---|---|
| Required, non-nullable, no default | `missing_required` error | type/nullability error | accept | error |
| Optional, non-nullable, no default | produce absent/empty `Optional[T]` | type/nullability error | accept as `T` | error |
| Nullable field | requiredness still applies | accept null | accept as `T` | error |
| Defaulted field | validate and use the default | nullability rule applies; do not replace null with default | accept supplied value | error |

Nullability is separate from omission. An optional Mojo `Optional[T]` does not automatically make JSON `null` valid. A nullable field must opt into null acceptance. Missing with a default uses the default; explicit null never triggers a default. Defaults are validated at schema construction/compile time where possible and otherwise checked before use.

At validation boundaries, the result is a complete typed model: there is no persistent “missing” sentinel unless a future API explicitly exposes partial models. If a caller needs to distinguish omitted input from a defaulted field after validation, that provenance must be an explicit opt-in feature; v1.0 does not promise it.

## Strictness and coercion

- Strict validation is the default.
- A value of the wrong source type fails; booleans are not integers; numeric strings are not numbers.
- JSON integer inputs must be mathematically integral and representable by the destination Mojo integer type. A fractional number cannot be truncated.
- Coercion is opt-in through an explicit policy. Each accepted conversion is documented and tested; there is no broad “best effort” conversion.
- Validation does not mutate caller-owned input. A transformation is a separate configured stage with a declared output type.

The exact set of coercions is a v0.4/v0.6 API decision and must be published as a conversion table before release.

## Ordering, errors, and paths

Validation proceeds in stable model field declaration order and, within a field, in this order:

1. Presence/default handling.
2. Nullability and source-type check.
3. Safe conversion, only if an explicit coercion policy allows it.
4. Built-in field constraints.
5. Field-level custom validators.
6. Nested value/model validation.
7. Model-level and cross-field validators, only when their required inputs are valid.

Independent field issues are aggregated in deterministic order. A type failure prevents constraints and validators that require the target type from running. Nested collections continue through independent elements unless a resource limit is reached.

An issue has a stable machine-readable code, a typed path, a human-readable message, and optional safe context. Paths are sequences of field-name and array-index segments; dotted text is only a display form because field names can contain dots or brackets. Raw input values are excluded from messages by default to avoid leaking secrets; applications may opt into safe input context where appropriate.

Safe APIs return a result value for invalid data. They do not terminate the process. A separately named convenience API may propagate a Mojo error, but callers must handle it. Syntax, validation, and serialization failures have distinct error categories and stable codes.

Unknown object fields are rejected by default. A per-model policy may reject, ignore, or preserve extras only when preservation has a sound typed representation. Ignored fields are deliberately discarded and that behavior is explicit at the call site/schema.

## Validators and transformation

Built-in constraints and custom validators are pure validation by default: they inspect input and report success/issues. A transforming validator is a separate operation whose input and output types are explicit. Field validators run in declaration order; model validators run after valid field values exist. A validator must not run on a value whose prerequisite type check failed.

The initial v1.0 contract is synchronous. Async validators, database lookups, and I/O-bound validation are out of scope.

## Value ownership and resource safety

Parsing external text produces owned values. Validated models own their fields and do not retain references into a temporary input buffer. Borrowed input views may be used internally only while their owner is live and must not escape the call. Any future zero-copy API requires a separate lifetime-aware contract and benchmarks.

Parsers must reject malformed input safely and enforce configurable/documented limits for input bytes, nesting depth, collection sizes, and accumulated errors. Exact defaults are a v0.4 decision backed by tests and realistic workloads; unbounded recursion or unbounded error accumulation is not acceptable for untrusted input.
