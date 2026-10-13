---
name: knowledge-hexagonal-architecture
description: Expert knowledge of Hexagonal Architecture (Ports & Adapters) from Cockburn's primary sources, the 2024 book "Hexagonal Architecture Explained", and practitioner experience. It covers port design and naming, the configurator, testing with fakes and contract tests, enforcement tooling, hard problems such as transactions, queries and errors, and pitfalls. Use when designing, implementing, reviewing or refactoring code with hexagonal, ports-and-adapters, clean or onion architecture; when deciding port boundaries, folder layout or wiring; when isolating a database or third-party API from business logic; or as a challenge lens on a design that claims to be hexagonal.
---

# Hexagonal Architecture (Ports & Adapters)

Intent, from Cockburn (2005):

> "Allow an application to equally be driven by users, programs, automated test or batch scripts, and to be developed and tested in isolation from its eventual run-time devices and databases."

The canonical name is **Ports & Adapters**. "Hexagon" is a drawing convenience, and the number six means nothing.

## The pattern

- **Two zones only: inside (the app) and outside (everything else).** The pattern says *nothing* about how the inside is structured.
  - It does not require domain/application/infrastructure rings, DDD, or use-case classes. Those come from Onion, Clean and DDD.
  - Cockburn: "Stop dragging them into the pic."
- **A port is a purposeful conversation, owned by the app.** It is named for its purpose, `For<Doing>Something`.
  - Driving example: `ForParkingCars`. Driven examples: `ForGettingTaxRates`, `ForNotifyingCustomers`.
  - Name a port by purpose, never by technology: `SmtpPort` and `SqlPort` are wrong.
- **Driving (primary) side:** actors that start a conversation with the app, such as a UI, CLI, test, consumer, cron job or another app.
  - Driving adapters *use* driving ports.
- **Driven (secondary) side:** what the app talks to. There are two kinds:
  - **repositories**, which return data in a round trip;
  - **recipients**, which are fire-and-forget (notifications, events).
  - Driven adapters *implement* driven ports.
- **The app owns both interfaces.**
  - A driving port is the app's *provided* interface.
  - A driven port is its *required* interface, so it is defined inside the app, never in the adapter's package.
- **Configurator (composition root).** One module knows every player and wires them together, and only there do source dependencies converge.
  - Each test case is also a configurator.
  - The pattern doesn't specify the configurator's design. It can use DI, a lookup or a broker.
- **Dependencies point inward.** On the driven side, the execution flow runs *opposite* to the source dependency.
  - The adapter depends on both the app's port and the vendor API.
  - The app depends on nothing.
- **Strong conformance:** a driven port speaks only domain concepts. It "can't even know that there is a database, let alone SQL."
  - A port expressed in SQL meets the letter of the pattern and defeats its purpose.

## Operative rules

1. **Build in Cockburn's order. The test harness is the first user.**
   1. Test → app → test double. Once this works, "the architecture is in place."
   2. Real driver → app → test double.
   3. Test → app → real driven adapter.
   4. Real → real.
2. **Every port gets at least two adapters: a real one and a test one.** "Make my blood freeze": Cockburn's reaction to hexagon claims that have no tests on both sides. A port without a test adapter is just an interface on a diagram.
3. **Use coarse ports.** Start with one port per actor. Typically there are 2–4 driving ports and up to about 7–8 driven ports.
   - Create a driven port per *external system*, not per domain concept (Garrido de Paz). An external system is one "whose interface your team can't change".
   - The opposite school (narrow per-use-case ports, one repository per aggregate) is legitimate. Pick one convention per codebase deliberately.
4. **Interfaces only where they earn it.**
   - Driven ports always need an interface, because that is where the inversion happens.
   - Driving ports can be the app service's public API. Cockburn now accepts both schools; just don't keep a foot in each.
5. **Adapters translate. They don't decide.**
   - An adapter handles syntax and shape validation, protocol mapping and exception translation.
   - Business rules, orchestration and "what to save" stay inside.
   - Adapters never call each other.
6. **Treat time, IDs, randomness and config as outside.** Make them driven ports, or better, pass them in as values (`now`, `newId`).
7. **Enforce the boundary mechanically from day one.** Layering fails because there is "no mechanism to detect when a violation occurs." Use architecture tests plus module or package visibility.
8. **Fakes over mocks.** Keep them honest by running one contract-test suite against both the fake and the real adapter.

## High-frequency pitfalls

| Smell | Fix |
|---|---|
| Port signature uses `Pageable`, `ResultSet`, ORM entity, `SQLException`, HTTP status | Core-owned value types and error set; adapter translates |
| `@Entity` / `@JsonProperty` on domain classes | Separate adapter models where shapes diverge (two-way mapping), or accept consciously |
| `IFooService` + `FooServiceImpl` everywhere | Delete single-impl interfaces that don't invert a dependency |
| Controller → repository directly | All traffic goes through the inside |
| Use case knows the transport ("returns 404") | Domain errors; driving adapter maps to protocol in one place |
| Generic `Repository<T,ID>` port | Consumer-shaped port with only the operations the app needs |
| Loading aggregates to render lists | Separate read/query ports returning projections |
| Five mocks per use-case test, verifying call order | In-memory fakes + state assertions |
| Hexagon around a CRUD form app | Don't. Or hex only the module with real rules |
| "We use hex so we can swap the DB" | Weakest justification. The real wins are testability, vendor-SDK isolation and deferred decisions |

## Challenge questions

- Can the whole app run through its driving ports with only in-memory adapters, with no DB, no network and no framework booted?
- For each port: who owns it, what is its purpose-name, and which two adapters (real and test) exist today?
- Does any port signature, type or exception reveal the technology behind it?
- What would change in the core if this vendor or SDK were replaced? It should be nothing.
- Where does the transaction boundary live, and does any adapter know about other adapters?
- Which interfaces have exactly one implementation and invert nothing?
- Is anything enforcing the dependency rule, or is it a promise?
- Is the hexagon paying for itself here, or is this CRUD wearing a costume?

## References (load as needed)

- [CANON.md](CANON.md): what Cockburn and Garrido de Paz actually say. Terminology, naming, port count, configurator, development stages, relation to Onion, Clean and DDD, and common misreadings.
- [PITFALLS.md](PITFALLS.md): the anti-pattern catalogue, each as symptom → why it hurts → fix.
- [HARD-PROBLEMS.md](HARD-PROBLEMS.md): mapping strategies, transactions and outbox, pagination, read side, N+1 and lazy loading, errors, auth, logging, clock and IDs.
- [IMPLEMENTATION.md](IMPLEMENTATION.md): folder layouts, naming, wiring, per-language idioms (Go, TS, Python, Java/Kotlin, .NET, Rust, FP), testing strategy, adapter catalogue.
- [ENFORCEMENT.md](ENFORCEMENT.md): ArchUnit, jMolecules, Spring Modulith, dependency-cruiser, eslint, import-linter, go-arch-lint/depguard, NetArchTest, build modules.
- [ADOPTION.md](ADOPTION.md): when not to use it, lightweight hex, migrating legacy code, functional variants (impureim sandwich, dependency rejection).
