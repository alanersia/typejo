# Miduct integration boundary

Typejo is a standalone foundational library. The dependency direction is:

```text
Miduct → Typejo
```

The reverse dependency is prohibited:

```text
Typejo → Miduct
```

## Suitable Miduct use cases

Miduct may call Typejo to validate HTTP request bodies, query/path parameters, and application configuration; deserialize typed data transfer objects; serialize responses; validate database-facing inputs; and export a Typejo-supported JSON Schema subset for OpenAPI integration.

These are integration examples, not Typejo implementation status. OpenAPI route generation and HTTP behavior belong to Miduct or another integration layer.

## Boundary rules

- Typejo accepts values/text/bytes and explicit options; it does not know about requests, routes, headers, status codes, databases, or middleware.
- Typejo does not install dependencies or choose a package manager.
- Typejo remains usable from an ordinary Mojo program without importing Miduct.
- Miduct translates Typejo parse/validation/serialization issues into its own transport behavior; Typejo's error model remains transport-neutral.
- JSON Schema interoperability is limited to the subset Typejo can truthfully export.

## Integration acceptance

Before v1.0, demonstrate one small non-framework Mojo application using Typejo directly and one integration application consuming Typejo without a reverse dependency. Verify that model errors keep field/index paths through the integration boundary and that serialization policies do not depend on HTTP response code.
