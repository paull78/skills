# Hard problems most hex conversations skip

## Mapping between boundaries (Hombergs, *Get Your Hands Dirty on Clean Architecture*)

| Strategy | Mechanics | Pros | Cons | Use when |
|---|---|---|---|---|
| No mapping | One domain class, annotated, used by web, app and persistence alike | Least code | Breaks SRP; a schema or JSON change becomes a domain change; risk of leaking fields | CRUD paths, or when all layers truly need the same shape. A fine start: switch when it hurts |
| Two-way | Each adapter has its own model and maps to and from the domain; ports speak domain types | Domain free of annotations; outer models evolve independently | Boilerplate; the domain still crosses the boundary | Default for persistence and external APIs |
| Full | A dedicated input/output model per operation (`SendMoneyCommand`) | Explicit per-use-case contract; validation in the command; no "which fields are set?" | Most code | web → app for state-changing commands |
| One-way | All layers implement a shared read-only "state" interface; the domain builds itself from it | Less copying | Confusing; only works when models are near-identical | Rarely |

- **Choose per boundary and per use case, not globally.**
  - Common mix: *full* mapping on web → app for commands, *two-way* for app ↔ persistence, and *no mapping* or direct projections for queries.
- **Don't share one input model across use cases.** It turns into a grab-bag of optional fields.
- **Who maps:** the adapter maps, because it's the only side that knows both models.
  - Exception: semantic translation of a foreign system's concepts belongs inside the hexagon (Garrido de Paz's "right boundary").
  - The adapter handles technology; the app handles meaning.

## Transactions and unit of work

- **The application service (use case) is the transaction boundary.** Only it knows which writes belong together. A persistence adapter can't know that, and a controller shouldn't.
- **Options, from purest to most pragmatic:**
  1. **Unit of Work port** (Cosmic Python). The core uses it as a context manager:
     ```python
     with uow:
         batch = uow.batches.get(ref)
         batch.allocate(line)
         uow.commit()
     ```
     The fake UoW records `committed = True`.
  2. **Transactional decorator** around the use case, applied in the configurator. The core stays annotation-free.
  3. **`@Transactional` on the application service.** This is Hombergs' BuckPal choice, a known and accepted compromise.
- **One aggregate per transaction.** Cross-aggregate consistency goes through domain events and eventual consistency (Vernon).
- **Transactional outbox.**
  - The use case writes the aggregate change and an outbox row in the same local transaction. A relay adapter then publishes to the broker.
  - The core sees a `ForPublishingEvents` port whose real adapter writes to the outbox table, never directly to Kafka.
  - Hidden coupling to document: that adapter must enlist in the same transaction as the repository adapter.
- **Publishing directly to a broker inside a database transaction is a dual-write bug.** It looks fine in in-memory tests and fails in production.

## Read side, queries and reporting

- **Queries may bypass the domain** (Graça: they return "raw data to be shown to the user").
- **Give reads their own query ports** that return projections or DTOs built directly by SQL or the search engine.
- **Don't load aggregates to render lists.**
- **Write side vs read side:** the write side gets the rich domain plus repository ports. The read side gets thin query ports and may share nothing with the domain. This is CQRS-lite, and it's fine.
- **Placement:** keep query ports and their DTOs in the app, so the driving adapter still talks only to the inside.

## Pagination, sorting, filtering

- **Core-owned types:** `PageRequest(offset|cursor, limit)`, a `SortKey` enum of *domain* fields (never column names), and filter value objects.
- **The adapter maps** sort keys to columns and rejects unknown ones.
- **Return a core `Page<T>`/`Slice<T>`.** Make the total count optional, because counts are expensive.
- **Treat cursor/keyset pagination as a port-level concept** if the data is large, rather than an adapter detail you'll have to retrofit.

## Performance: N+1, chatty ports, lazy loading

- **Narrow ports invite N+1 calls.** A loop of `loadX(id)` calls means each call crosses the network.
  - Design ports for the use case's batch need (`loadAccounts(Set<Id>)`).
  - Measure the call count.
- **Lazy loading across a port is a leak.** The core's behaviour then depends on whether an ORM session is open (`LazyInitializationException`).
  - Load complete aggregates eagerly.
  - Reference other aggregates by ID.
- **Some capabilities are asymmetric between technologies** (full-text search, joins, atomic counters).
  - When the core depends on such a capability, put it in the port contract explicitly (`ForSearchingProducts`).
  - Don't pretend it's portable.

## Errors across the boundary

- **The core defines a closed error vocabulary,** for example `NotFound`, `Conflict` / `AlreadyExists`, `RuleViolated(reason)`, `NotAllowed`, `DependencyUnavailable`.
- **Driven adapters translate infrastructure failures into it:**
  - unique-constraint violation → `EmailAlreadyTaken`;
  - timeout → `DependencyUnavailable`;
  - vendor 402 → `PaymentDeclined`.
- **Driving adapters map the vocabulary to protocol in one place per adapter:** HTTP 404/409/422/503, gRPC codes, CLI exit codes, retry or DLQ for consumers.
- **The use case never chooses a status code.** No HTTP types inside.
- **Choose one mechanism per codebase:** exceptions *or* `Result`/`Either`. A `Result` makes failure part of the port's contract, which is useful at driven ports.
- **Retries, circuit breakers and timeouts are adapter concerns.**
  - Apply them as decorators in the configurator.
  - The core sees only `DependencyUnavailable`.

## Security and authorization

- **Authentication** (tokens, sessions, signatures) lives in the driving adapter. It produces a core-owned `Actor`/`Principal` value passed into the port call.
- **Authorization:**
  - Coarse role checks go at the driving-port boundary.
  - Data-dependent checks ("is this the owner of the order?") go inside, because they need state.
- **Separate driving ports per actor role** are justified when permissions differ (Cockburn/Garrido: manager vs clerk).
- **An external identity or permission service** is just another driven port.

## Logging, metrics, tracing

- **Technical telemetry belongs in adapters,** or in decorators wrapped around ports in the configurator.
- **Business-meaningful records** (audit trail, "order placed") are domain events or an explicit driven port (`ForRecordingAuditEvents`), and they are tested like any other output.
- **Don't inject a `Logger` port into every entity.** Pure logging facades aren't the coupling the pattern exists to prevent.

## Time, IDs, randomness, configuration

- **These are all outside.** Noback: core code doesn't need "a specific environment to run in", and asking for the current time is infrastructure.
- **Best: dependency rejection.** The shell passes `now`, `newId` and random values in as *values*.
- **Next best:** `Clock`, `IdGenerator` and `RandomSource` driven ports, with fixed and sequential fakes.
- **Database-generated IDs force save-then-read** and break aggregate creation in the core. Prefer app-generated UUID/ULID values.
- **Configuration:** the configurator reads env and files and passes *typed values* to constructors. The core never reads env vars or config files.
- **Feature flags** read at runtime are a driven port (`ForCheckingFeatures`). Flags read at startup are configuration values.

## Events and messaging

- **Inbound messages:** the consumer is a driving adapter. It deserializes, handles idempotency keys and deduplication if those are technical, calls one port operation, then acks or nacks according to the core result.
- **Idempotency rules that are business rules** ("an order can't be paid twice") live inside.
- **Outbound:** a recipient-style driven port named by purpose (`ForNotifyingWarehouse`), never `KafkaProducerPort`.
- **Message schemas belong to the adapter.** Domain events are core types. The adapter maps them to wire formats, and versions those formats independently.
