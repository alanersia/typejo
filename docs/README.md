# Typejo documentation

Typejo is a standalone Mojo library for validating, parsing, and serializing structured data. This directory is the product and technical reference; the roadmap labels each milestone as implemented, planned, or deferred.

## Current status

v0.1 primitive validation and the v0.2 composite validation foundation are implemented and verified with Mojo 1.1.0. Composite inputs use a Typejo-owned `InputValue` tree and explicit `TypejoModel` adapters; JSON parsing and serialization remain planned. See the [implementation status and roadmap](roadmap.md).

## Guides

- [Roadmap and milestone acceptance criteria](roadmap.md)
- [Architecture overview and boundaries](architecture/overview.md)
- [Mojo compatibility notes](architecture/mojo-compatibility.md)
- [Core validation semantics](specifications/semantics.md)
- [Parsing, serialization, and schema boundaries](specifications/data-formats.md)
- [API contract and implementation status](api/overview.md)
- [Pydantic v2 and Zod comparison](comparisons/pydantic-zod.md)
- [Miduct integration boundary](integrations/miduct.md)
- [Testing, benchmarking, and release readiness](development/release-readiness.md)

## Status vocabulary

- **Implemented:** present in this repository and verified against its supported compiler.
- **Proposed:** a design target; signatures and behavior may change before implementation.
- **Planned:** assigned to a roadmap milestone but not implemented.
- **Deferred:** intentionally outside the v1.0 target or gated on a technical feasibility review.

The roadmap and API contract distinguish implemented v0.1/v0.2 behavior from later Typejo targets. Mojo language facts are labeled separately from Typejo design choices and link to the official Mojo 1.1.0 documentation where possible.
