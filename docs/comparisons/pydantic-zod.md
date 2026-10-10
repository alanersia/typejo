# Typejo, Pydantic v2, and Zod

This is a capability comparison, not a parity claim. Pydantic refers to the v2 API; Zod refers to the current Zod 4 documentation. Typejo implements v0.1 primitive validation; remaining roadmap features are planned. **“Planned” means a v1.0 target, not a shipped feature.** Status labels mean Supported, Planned, Partially supported, Unsupported, or Not applicable. Vendor behavior can change; source links below are the references reviewed for this page.

| Representative capability | Typejo current | Typejo v1.0 target | Zod | Pydantic v2 |
|---|---|---|---|---|
| Primitive and constrained values | Partially supported: v0.1 primitives and basic constraints | Planned: model fields and broader constraints | Supported | Supported |
| Typed model definition | Unsupported | Planned: native Mojo structs, derive/adapter feasibility gated | Supported: schema values infer TypeScript output types | Supported: annotated model classes |
| Strict validation | Partially supported: primitive type checks are strict | Planned: strict by default for structured inputs | Supported through schema/coercion choices | Supported; lax behavior is common default and strict mode is configurable |
| Explicit coercion | Unsupported | Planned: opt-in documented conversion table | Supported through coercion schemas and transforms | Supported through lax conversion rules and strict mode |
| Optional, nullable, missing/default semantics | Unsupported | Planned with distinct input-state rules | Supported (`optional`, `nullable`, defaults) | Supported through optional annotations, defaults, and requiredness semantics |
| Nested model/collection validation | Unsupported | Planned | Supported | Supported |
| Safe structured errors with paths | Partially supported: stable primitive errors at the root path | Planned: typed nested paths and model errors | Supported through `safeParse` and issue paths | Supported through `ValidationError` details and locations |
| JSON text to typed value | Unsupported | Planned; parser strategy unresolved | Partially supported: parse JavaScript values; JSON text parsing is separate from core schema parsing | Supported through JSON model validation APIs |
| Typed value to JSON | Unsupported | Planned for documented Mojo/JSON subset | Partially supported: callers commonly use JavaScript serialization; no equivalent general model dump contract is targeted here | Supported through model dump/JSON APIs |
| Custom and cross-field validators | Unsupported | Planned, synchronous v1.0 target | Supported through refinements/checks and transforms | Supported through field/model validators |
| JSON Schema generation | Unsupported | Planned for documented subset and dialect | Supported, with limitations by schema type | Supported, with customization and unsupported-type limitations |
| Compile-time specialization | Unsupported | Deferred to v2 feasibility work | Not applicable: TypeScript/JavaScript schema runtime | Not applicable: Python runtime validation engine |
| Streaming/zero-copy/batch validation | Unsupported | Deferred; no v1 promise | Not applicable: not a core schema guarantee | Not applicable: not a core model-validation guarantee |

## Trade-offs

- **Mojo-native model ergonomics:** Typejo should use struct types and compile-time mechanisms where verified. Whether a struct can serve as a low-boilerplate schema without duplicate field declarations is a v0.3 engineering question.
- **Strictness:** Typejo targets strict-by-default conversion to avoid surprising data changes. This differs from Pydantic's commonly permissive default and Zod's explicit schema/coercion APIs; coercion must be visible.
- **Parsing:** Pydantic includes JSON validation entry points. Zod validates JavaScript values and exposes schema parsing; applications separately parse JSON text. Typejo targets both stages with distinct error categories.
- **Performance:** Mojo compile-time specialization may reduce runtime dispatch, but increases compile work/code size and has not been measured for Typejo. No speed claim is made.
- **Scope:** Typejo v1.0 targets a well-defined application-level subset. It does not promise complete Pydantic or Zod parity, ORM behavior, HTTP integration, or schema support beyond its documented JSON Schema subset.

## References

- [Zod basics: parsing, safe parsing, inferred types](https://zod.dev/basics)
- [Zod API: optional, nullable, objects, refinements](https://zod.dev/api)
- [Zod JSON Schema](https://zod.dev/json-schema)
- [Pydantic models](https://docs.pydantic.dev/latest/concepts/models/)
- [Pydantic strict mode](https://docs.pydantic.dev/latest/concepts/strict_mode/)
- [Pydantic validators](https://docs.pydantic.dev/latest/concepts/validators/)
- [Pydantic JSON Schema](https://docs.pydantic.dev/latest/concepts/json_schema/)
