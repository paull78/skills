# Enforcing the boundary

Cockburn on why layering fails: there is "no mechanism to detect when a violation of that promise occurs". These are the mechanisms.

**Use the cheapest strong mechanism first:**
1. Build modules or compilation units (strongest).
2. Language visibility (`internal`, package-private, `pub(crate)`).
3. An architecture test or linter in CI.

Snippets marked *(adapted)* combine a tool's documented syntax with hexagon-specific patterns. Check them against current docs before you rely on them.

## Rules to encode, whatever the tool

1. The core (`domain` and `application`) imports nothing from adapters, frameworks, ORMs, HTTP or SDKs.
2. Adapters import the core, and never each other.
3. Only the configurator imports everything.
4. Bounded contexts don't reach into each other's internals.

## Java / Kotlin

**ArchUnit.** In ArchUnit's docs, `onionArchitecture()` is also the Hexagonal / Ports & Adapters rule, and it forbids adapters from depending on each other.
```java
@AnalyzeClasses(packages = "com.myapp")
class ArchitectureTest {
  @ArchTest static final ArchRule hexagon = onionArchitecture()
      .domainModels("com.myapp.domain.model..")
      .domainServices("com.myapp.domain.service..")
      .applicationServices("com.myapp.application..")
      .adapter("rest", "com.myapp.adapter.rest..")
      .adapter("persistence", "com.myapp.adapter.persistence..");

  @ArchTest static final ArchRule domainIsPure = noClasses()
      .that().resideInAPackage("com.myapp.domain..")
      .should().dependOnClassesThat()
      .resideInAnyPackage("org.springframework..", "jakarta.persistence..");
}
```
- Dependency: `com.tngtech.archunit:archunit-junit5`.
- BuckPal ships its own fluent `HexagonalArchitecture` DSL on top of ArchUnit, if you want a port-aware vocabulary.

**jMolecules.**
- Annotate *packages* in `package-info.java` with `@PrimaryPort`, `@SecondaryPort`, `@PrimaryAdapter`, `@SecondaryAdapter` or `@Application`. This keeps annotations off the domain classes.
- Rule: `@ArchTest ArchRule hex = JMoleculesArchitectureRules.ensureHexagonal();` (STRICT by default).
- Artifact: `org.jmolecules.integrations:jmolecules-archunit`.

**Spring Modulith.**
- `ApplicationModules.of(App.class).verify()` enforces boundaries *between* contexts.
- Add the hexagon rule inside each context with `.verify(VerificationOptions.defaults().withAdditionalVerifications(JMoleculesArchitectureRules.ensureHexagonal(VerificationDepth.STRICT)))`.

**Build modules.**
- Use `:domain`, `:application`, `:adapter-web`, `:adapter-persistence`, `:bootstrap`, wired with `implementation` (not `api`).
- Optionally add JPMS `exports` (BlueZone does).

## TypeScript / JavaScript

**dependency-cruiser** *(adapted)*
```js
// .dependency-cruiser.js   — run: npx depcruise src
module.exports = { forbidden: [
  { name: 'core-imports-nothing-outside', severity: 'error',
    from: { path: '^src/[^/]+/(domain|application)/' },
    to:   { pathNot: '^src/[^/]+/(domain|application)/' } },   // also blocks npm pkgs; add allow-list
  { name: 'no-adapter-to-adapter', severity: 'error',
    from: { path: '^src/[^/]+/adapters/([^/]+)/' },
    to:   { path: '^src/[^/]+/adapters/', pathNot: '^src/[^/]+/adapters/$1/' } },
  { name: 'no-cross-context-internals', severity: 'error',
    from: { path: '^src/([^/]+)/' },
    to:   { path: '^src/([^/]+)/(domain|adapters)/', pathNot: '^src/$1/' } },
]};
```
- `$1` back-references a group captured in `from.path`.

**eslint-plugin-boundaries (v7+)** *(adapted)*
- The old `element-types` rule is deprecated. Use `boundaries/dependencies` with `default` plus `policies`.
```js
settings: { "boundaries/elements": [
  { type: "domain", pattern: "src/*/domain" },
  { type: "application", pattern: "src/*/application" },
  { type: "adapter", pattern: "src/*/adapters/*" } ] },
rules: { "boundaries/dependencies": [2, { default: "disallow", policies: [
  { from: { element: { type: "adapter" } },     allow: { to: { element: { types: { anyOf: ["application","domain"] } } } } },
  { from: { element: { type: "application" } }, allow: { to: { element: { type: "domain" } } } },
]}]}
```

**Zero-dependency option:** core ESLint `no-restricted-imports`, scoped with `files: ["src/**/domain/**", "src/**/application/**"]`:
```js
{ patterns: [{ group: ["**/adapters/**", "express", "pg", "@aws-sdk/*"], message: "core must stay technology-free" }] }
```

## Python

**import-linter** (`pyproject.toml`; run with `lint-imports`)
```toml
[tool.importlinter]
root_package = "shop"
include_external_packages = true          # needed to forbid third-party packages

[[tool.importlinter.contracts]]
name = "Hexagon layering per context"
type = "layers"
containers = ["shop.orders", "shop.billing"]
layers = ["entrypoints | adapters", "application", "domain"]   # high → low; '|' = independent siblings

[[tool.importlinter.contracts]]
name = "Domain is technology-free"
type = "forbidden"
source_modules = ["shop.orders.domain", "shop.billing.domain"]
forbidden_modules = ["sqlalchemy", "fastapi", "requests"]

[[tool.importlinter.contracts]]
name = "Contexts are independent"
type = "independence"
modules = ["shop.orders", "shop.billing"]
```
- Wildcard module patterns (`shop.*.domain`) exist in recent versions. Check what your version supports, or list modules explicitly as above.
- In the `layers` contract, `adapters` and `entrypoints` are independent siblings, so they can't import each other.

## Go

- **`internal/`** is a compiler-enforced boundary. Put each context under `internal/<context>/`.
- **go-arch-lint** (`.go-arch-lint.yml`) *(adapted)*:
  ```yaml
  version: 3
  workdir: internal
  components:
    domain:   { in: "*/domain/**" }
    app:      { in: "*/app/**" }
    adapters: { in: "*/adapters/**" }
  deps:
    app:      { mayDependOn: [domain] }
    adapters: { mayDependOn: [app, domain] }
  ```
- **depguard** (golangci-lint): add a rule scoped to `files: ["**/domain/**", "**/app/**"]` that denies `database/sql`, `net/http` and ORM or SDK packages.
- **go-cleanarch** is an alternative.

## .NET

- **First line of defence:** project references (`Domain` references nothing).
- **NetArchTest:**
  ```csharp
  Types.InAssembly(typeof(Order).Assembly).That().ResideInNamespace("MyApp.Domain")
       .ShouldNot().HaveDependencyOn("Microsoft.EntityFrameworkCore").GetResult().IsSuccessful
  ```
- **ArchUnitNET:**
  ```csharp
  Types().That().Are(DomainLayer).Should().NotDependOnAny(AdapterLayer).Check(Architecture)
  ```

## Rust

- **Crate boundaries:** Cargo rejects cycles between crates, and the `domain` crate's `Cargo.toml` simply doesn't list infrastructure crates.
- **Visibility:** `pub(crate)` hides internals.
- **CI check:** add a `cargo tree` check, or `cargo-deny`, if you need to ban transitive dependencies.

## PHP

- **Deptrac:** define layers by namespace and set the allowed dependencies (Graça and Noback both recommend it).

## Tips

- **Start the architecture test on day one.** On a legacy codebase, scope it to the new packages and ratchet it wider over time.
- **Assert purity in two directions:**
  - "core doesn't import adapters";
  - "core doesn't import frameworks or SDKs". This second rule is the one that usually rots first.
- **Make violations fail the build.** Warnings get ignored.
- **When a rule needs an exception, write it down** in the config with a comment explaining why. Silent allow-lists are how boundaries erode.
