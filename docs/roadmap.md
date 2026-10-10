# Typejo roadmap

All milestones below are planning targets. **No Typejo feature is implemented yet.** A milestone is complete only when its acceptance criteria and tests pass on the documented supported Mojo version.

## v0.1 — Validation Foundation

**Deliver:** primitive validation for `String`, `Int`, floating-point scalar, and `Bool` inputs; explicit type mismatch; basic numeric and string constraints; strict mode; deterministic validation results; structured errors with stable codes, paths, and messages.

**Acceptance:** strict validation rejects values of the wrong input type without implicit conversion; constraints run only after type checks; equivalent inputs produce errors in the same order; safe validation returns a result rather than terminating the program; every error carries a code, path, and actionable message.

**Tests:** valid and invalid primitive cases; numeric boundaries; string length boundaries; wrong-type cases including booleans supplied as numbers; stable error code/path/order assertions; safe error handling.

## v0.2 — Composite Validation

**Deliver:** optional and nullable fields; missing/null/invalid/defaulted distinctions; lists and nested collections; required fields and defaults; nested models and paths; unknown-field policy; basic collection constraints.

**Acceptance:** missing, null, invalid, and defaulted values follow [the semantics specification](specifications/semantics.md); nested errors retain typed field/index path segments; unknown fields follow an explicit policy; collection length and item validation produce deterministic results.

**Tests:** a truth table for missing/null/default/invalid; nested object and list failures; unknown-field modes; empty/min/max collection boundaries; default application and invalid-default rejection.

## v0.3 — Typed Model Foundation

**Deliver:** typed Mojo struct integration; reusable model definitions; field metadata and constraints; model-level validation; generic validation interfaces; validated outputs with the requested concrete type; minimal model boilerplate.

**Acceptance:** one model declaration is the source of truth for field types; users do not re-declare the same fields in a separate validator; errors map back to model fields; a compile-time reflection prototype is evaluated on the supported compiler. If reflection cannot safely derive and construct a model, publish and test an explicit trait/adapter route and document the unavoidable mapping once.

**Tests:** compile-time checks for model conformance and unsupported field types; valid construction; field and model failures; nested model composition; non-copyable or ownership-sensitive field behavior where supported.

**Feasibility gate:** field enumeration is available in Mojo 1.1.0, but automatic metadata attachment, safe field access, and construction of arbitrary structs as one end-to-end derive flow must be proven before promising a derive API.

## v0.4 — Parsing and Deserialization

**Deliver:** JSON text parsing; JSON-to-model validation; nested objects, arrays, and composite values; explicit coercion policy; strict and permissive modes; safe malformed-input errors.

**Acceptance:** syntax errors are distinguishable from schema errors; malformed input is returned as an error and does not unexpectedly terminate the application; no coercion occurs unless selected; depth, input-size, and collection limits are enforced and documented.

**Tests:** malformed JSON categories; valid and invalid nested payloads; coercion matrix; integer range and numeric precision boundaries; escaping and Unicode; size/depth limit boundaries; fuzzing of parser entry points where practical.

**Feasibility gate:** the audited Mojo 1.1.0 standard-library index does not list a JSON package. Before this milestone, choose and document a Typejo-owned parser or an acceptable standalone Mojo dependency; do not assume a standard-library API exists.

## v0.5 — Serialization

**Deliver:** typed model-to-JSON output; nested serialization; optional/null/default policies; field inclusion and exclusion; stable public API and predictable output.

**Acceptance:** supported values serialize to valid JSON; behavior for absent, null, defaulted, and excluded fields is specified; object output order is either stable by declaration or explicitly unspecified; unsupported values return a structured error; serialization never silently loses unsupported data.

**Tests:** round trips for supported types; nested models and collections; inclusion/exclusion; optional/null/default policy; escaping; deterministic formatting contract; unsupported-type errors.

## v0.6 — Advanced Validation

**Deliver:** custom field and model validators; cross-field validation; reusable constraints; custom messages; composition; opt-in input coercion and transformations where the type contract can remain safe.

**Acceptance:** ordering is documented: decode/type check, built-in constraints, field validators, then model validators; a stage does not receive a value that failed its prerequisite type checks; error paths and aggregation remain deterministic; transformations declare their output type and cannot masquerade as validation-only checks.

**Tests:** ordering probes; field/model failures; cross-field paths; custom code/message; composed constraints; transformation input/output types; validator failure propagation.

## v0.7 — Schema Interoperability

**Deliver:** JSON Schema generation for a documented subset; field/model descriptions; required and optional field representation; nested definitions and references where supported; explicit dialect selection.

**Acceptance:** every emitted keyword corresponds to behavior Typejo actually enforces; unsupported constraints fail or are reported rather than silently omitted; dialect and subset are named; generated schemas validate against the selected dialect's meta-schema.

**Tests:** golden schemas for representative models; required/nullable/nested cases; references; unsupported-feature diagnostics; meta-schema validation.

## v0.8 — Developer Experience

**Deliver:** consistent names and exports; complete examples and integration recipes; actionable errors; strongly typed results; migration and upgrade guidance.

**Acceptance:** a new user can define a model, validate structured input, handle errors, and serialize output from one concise documented path; examples compile on the supported compiler; API names follow one convention; no example implies unavailable TypeScript/Python syntax.

**Tests:** compile every example; public API import checks; documentation link checks; migration examples for any API changes.

## v0.9 — Production Readiness

**Deliver:** correctness and invalid-input review; fuzz/property tests where practical; memory-safety review; profiling and representative benchmarks; supported Mojo/compiler policy; platform and security/resource-limit review; integration applications; API stability review.

**Acceptance:** no known data-loss or unsafe-input issue remains open without an explicit limitation; benchmark workloads and environments are reproducible and comparable; supported compiler/platform combinations are stated; resource limits and unsupported formats are published; all v1.0 requirements have passing evidence.

**Tests and evidence:** unit, integration, regression, boundary, and malformed-input suites; fuzz/property reports where available; allocation/latency profiles; API compatibility review; no performance claim without recorded measurements.

## v1.0 — Stable Production Release

**Deliver:** stable documented APIs for typed validation, nested/composite models, constraints, custom validators, strict and configured coercion, JSON parsing/serialization, structured errors, and a documented JSON Schema subset.

**Acceptance:** the defined application-level use cases in this roadmap work without Miduct or Python at runtime; model output is strongly typed; error behavior is safe and stable; JSON/schema boundaries and limits are documented; a compatibility and version policy exists; comprehensive examples, tests, and limitations are published. This is production readiness for a defined scope, not full Pydantic or Zod parity.

## v2.0 — Compiled Schema Engine (feasibility gated)

Investigate compile-time schema specialization, generated validators, reduced dispatch/reflection overhead, compile-time constraint checks, schema compatibility/evolution, additional formats, streaming, batch, and safe zero-copy paths.

**Acceptance gate:** each feature must be supported by the Mojo compiler/runtime, preserve v1 semantics, and show a measured benefit on representative workloads. Keep runtime fallbacks where needed. Do not promise code generation, zero-copy, streaming, or unrestricted format adapters before a prototype and benchmark establish feasibility.
