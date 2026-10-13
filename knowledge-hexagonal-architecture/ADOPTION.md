# Adoption: when, how much, how to migrate, functional variants

## When it pays

- **Isolation for testing.** You can run the whole app's behaviour without a database, network or framework. This is Cockburn's original and strongest reason.
- **Volatile or vendor integrations.** Examples: payment, SMS, a rates provider, a partner API. A port keeps SDK types out of business logic, so a vendor migration touches one adapter.
- **Multiple drivers.** The same logic is driven from HTTP, CLI, a queue, a batch job and tests.
- **Deferring infrastructure decisions.** You can build and test the core before the database or broker is chosen. Noback: no "entire Sprint Zero" on infrastructure.
- **Rich domain rules** that deserve to be read and tested on their own.

## When it doesn't pay

- **Forms over tables (CRUD) and reporting.** Hombergs: "probably overhead".
- **Thin integration or ETL pipes** with no rules.
- **Short-lived prototypes.**
- **A team that won't enforce it.** A half-applied hexagon is worse than an honest layered app.
- **"So we can swap the database" as the main reason.** That's the weakest justification: it rarely happens, and capability differences leak anyway.

Cockburn: "This pattern trades complexity for flexibility". Use it where you foresee swapping receivers, and nowhere else.

## Lightweight hex (scaling down)

This keeps most of the benefit for a fraction of the cost:
- One module, with two packages: `core` and `adapters`.
- Interfaces only for driven dependencies on things you don't own or can't run in tests.
- No driving-port interfaces. Concrete application services *are* the API.
- In-memory fakes for each driven port, plus one contract suite each.
- One architecture test: "core imports nothing from adapters or frameworks".
- Time and IDs passed in as values.

**Mixing with vertical slices:**
- Hex works per slice or module.
- Simple CRUD slices can talk to the database directly.
- Slices with real rules get a hexagon.
- Make the rule explicit, so readers know which kind of slice they're in.

## Migrating a legacy codebase

1. **Characterize first.** Add characterization tests and find the seams (Feathers).
2. **Wrap one painful external dependency.** Choose the one that blocks tests or is about to change: a payment SDK, email, or a flaky third-party API.
   - Create a core-owned port named by purpose.
   - Move every vendor call into one adapter.
   - Add a fake and narrow integration tests.
   - Restructure nothing else yet.
3. **Carve out one use case.** Move the logic from the controller into an application service that takes plain inputs. The controller becomes the first driving adapter, and a test becomes the second.
4. **Introduce clock and ID values early.** It's cheap and makes tests deterministic.
5. **Add an architecture test scoped to the new packages only,** then widen it over time. Don't big-bang it.
6. **At system scale, use a strangler fig.** A façade routes traffic to legacy or new code and is designed to disappear.
   - An anti-corruption layer translates the legacy model into the new domain. Semantic translation belongs inside the hexagon; technology translation belongs in the adapter.
7. **Data ownership is the hard part.** During the overlap, decide who writes which tables. Sync with outbox or change data capture (CDC), never with dual writes.

Cockburn and Garrido de Paz: "Tests make a line drawn around a subsystem real."

**Converting a layered app to hexagonal** (Zihler, endorsed in the book) takes two steps:
1. Invert the dependencies from business logic to data access.
2. Move the interface definitions into the app.

## Functional variants

- **Functional core, imperative shell** (Gary Bernhardt): pure decisions sit in the core, and a thin shell does the I/O.
  - The core is unit-tested with values.
  - The shell gets a few integration tests.
- **Dependency rejection** (Seemann): turn indirect inputs and outputs into direct ones.
  - Indirect input (data fetched from a dependency) becomes a parameter.
  - Indirect output (a call to a dependency) becomes a return value. For example, `tryAccept` returns `Reservation option` instead of calling `createReservation`.
  - "Dependencies are, by their nature, impure". Injecting impure functions into the core is "still not a functional approach".
  - No mocks are needed.
- **Impureim sandwich:** read (impure) → decide (pure) → write (impure).
  - It's "conspicuously often possible".
  - It breaks down with **cascading reads**, where what to fetch next depends on a decision.
  - Fallbacks: several stacked sandwiches, lazy values, free monads or effects in Haskell, or, in OO, injected ports for that use case only.
- **Seemann:** "Good functional design is equivalent to the Ports and Adapters architecture."
  - Haskell's `IO` makes purity a compile-time "pit of success".
  - In OO it's a convention, so enforce it (see ENFORCEMENT.md).
- **James Shore's A-Frame:** logic and infrastructure are peers under a thin application layer, and the application layer runs the sandwich.

## Practical OO hybrid (often the best default)

```text
application service (the sandwich):
  state    = ticketStore.find(id)                 # impure: driven port
  decision = Parking.decide(state, cmd, now)      # pure domain, takes everything as values
  ticketStore.store(decision.ticket)              # impure: driven port
  notifier.notify(decision.events)                # impure: recipient port
```

- **Most tests hit the pure middle** with plain data.
- **The application service gets a few tests** with in-memory fakes.
- **Each adapter gets contract tests.**
- **A handful of end-to-end tests** prove the wiring.
