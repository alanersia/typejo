# Mojo compatibility notes

**Support baseline:** local `mojo --version` reported Mojo 1.1.0. v0.1 through v0.4 are verified with that compiler; recheck compiler-sensitive details before release.

## Verified language facts

| Area | Verified in official Mojo 1.1.0 documentation | Typejo consequence |
|---|---|---|
| Structs | Struct fields have declared static types; struct shape is fixed at compile time. Structs are not dynamically extensible classes. | Model mapping must work with declared fields; do not promise runtime-added fields. |
| Generics and traits | Type/value parameters and trait bounds support reusable, statically checked code; generic code is specialized for concrete types. | Generic validators are viable in principle, but each required bound and instantiation must compile on the baseline. |
| Compile-time programming | `comptime` supports compile-time evaluation and specialization; compile-time loops can increase code size and compile time. | Treat generated/specialized validators as an optimization to measure, not a free abstraction. |
| Reflection | Mojo 1.1.0 reflection is incomplete and evolving. Typejo's probe verifies field names/types and `field_ref` access for `String`, `Int`, `Optional[String]`, and `List[String]`. | These checks support inspection and typed access only; they do not prove safe arbitrary model construction. Typejo keeps explicit adapters. |
| Errors | Mojo errors propagate through function calls and can be handled with `try`/`except`; an unhandled error terminates the program. | Safe validation of untrusted input should return an explicit result/error value and must not rely on an unhandled raised error. |
| Ownership | Values have owners; references have tracked origins/lifetimes; the compiler checks lifetime validity. | Parsers and validators must define whether they own, copy, consume, or borrow inputs. Do not return views into short-lived input buffers without an explicit lifetime contract. |
| Standard library JSON | No standard JSON parser/serializer API was verified for Mojo 1.1.0. | v0.4 uses a small Typejo-owned parser; serialization remains a later milestone. |

## Unverified or unsupported assumptions

- Automatic derivation of a typed Mojo model from a `struct` plus field metadata has not been demonstrated; v0.2 uses explicit `TypejoModel` adapters.
- Runtime reflection or dynamic field access equivalent to Python's object model is not assumed.
- JSON parsing/serialization is not assumed to be in Mojo's standard library; current parsing is implemented by Typejo.
- Annotations, macros, decorators, or generated code must not be assumed to provide a derive system without a compiler-checked prototype.
- Compiler specialization does not guarantee faster end-to-end validation; compile time, code size, allocation, and runtime must be measured.

## Engineering rule

Every public example and implementation must compile against the declared minimum Mojo version. Pin a support range only after CI covers it; review changelogs and rerun compatibility checks when updating the compiler. Current syntax may differ from earlier Mojo releases, so use the versioned manual and release notes rather than old examples.

## Sources

- [Mojo v1.1.0 release notes](https://mojolang.static.modular.com/releases/v1.1.0/)
- [Mojo standard library reference, version 1.1.0](https://mojolang.org/docs/std/)
- [Generics and parameterization](https://mojolang.org/docs/manual/generics/)
- [Reflection and introspection](https://mojolang.org/docs/manual/metaprogramming/reflection/)
- [Error handling](https://mojolang.org/docs/manual/errors/)
- [Ownership and lifetimes](https://mojolang.org/docs/manual/values/ownership/)
