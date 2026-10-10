# Testing, benchmarking, and release readiness

**Current status:** v0.1 primitive validation and v0.2 composite validation have passing tests and runnable examples verified with Mojo 1.1.0. Benchmarks, CI policy, JSON integration, and a supported-platform matrix remain future work. This page defines evidence required before v1.0.

## Correctness tests

- Unit tests for primitive types, every implemented constraint boundary, strictness, defaults, nullability, error codes, and path segments. Coercion tests belong to later milestones because coercion is not implemented.
- Composite/nested tests covering missing, null, invalid, defaulted, unknown, and deeply nested values.
- Regression tests for every fixed bug and every published compatibility behavior.
- Integration tests from JSON text through a typed model and back to JSON.
- Compile-time examples for model conformance and unsupported declarations.
- Compile every documentation example against the supported Mojo compiler.
- Fuzz or property-based testing of untrusted parser input where practical; preserve minimized failures as regressions.

## Safety and resource handling

Test malformed, oversized, deeply nested, and high-error-count inputs. Set and document bounds for bytes, nesting, collection size, and reported issues before production release. Ensure safe APIs return errors and do not expose partially initialized models. Review allocation, ownership transfer, borrowed views, integer overflow, float edge cases, and secret leakage in diagnostics.

## Benchmarks

Benchmark only after semantics are fixed. Record compiler version, target, optimization flags, CPU/OS, workload shape, input size, warm-up, repetitions, allocation counts where available, and raw results. Compare alternatives only on equivalent input, output, coercion, and error-aggregation behavior. Publish no unsupported performance claim. Track compile time and generated code size as well as runtime.

## Compatibility and release checklist

- Name a minimum supported Mojo version and test it in CI.
- Review compiler release notes for changes to reflection, generics, error handling, ownership, imports, and standard-library APIs.
- State supported OS/architecture targets based on actual CI results.
- Publish stable API and semantic guarantees for v1.0; mark experimental APIs clearly before then.
- Version the JSON Schema dialect and supported subset.
- Build a direct Typejo example and an integration example without Miduct dependency leakage.
- Resolve every documentation link and compile every code example.
- Archive benchmark methodology and results; no invented numbers.
