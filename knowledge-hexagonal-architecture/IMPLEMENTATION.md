# Implementation: layout, naming, wiring, idioms, testing

## Folder layouts

**Rule: split by bounded context or feature first, then by hexagon internals.** One composition root per deployable.

**Cockburn / Garrido de Paz (BlueZone reference implementation):**
- Separate build modules, one per adapter, each named after its port.
- Test doubles are first-class adapter modules.
- JPMS `module-info.java` enforces the boundaries.

```
bluezone-hexagon/          ports/driving/forparkingcars/ForParkingCars.java
                           ports/driven/forobtainingrates/ForObtainingRates.java (+ its DTOs)
                           CarParker, RateCalculator, ...
bluezone-adapter-forobtainingrates-stub/
bluezone-adapter-forstoringtickets-fake/
bluezone-adapter-forpaying-spy/
bluezone-adapter-forparkingcars-webui/
bluezone-driver-forparkingcars-test/     # Cucumber: the test harness is a driving adapter
bluezone-startup/                        # configurator
```

**Hombergs (BuckPal, Spring community default):**
```
<context>/adapter/in/web/        SendMoneyController
<context>/adapter/out/persistence/  AccountPersistenceAdapter, AccountJpaEntity, AccountMapper
<context>/application/port/in/   SendMoneyUseCase, SendMoneyCommand
<context>/application/port/out/  LoadAccountPort, UpdateAccountStatePort
<context>/application/domain/{model,service}/
config/                          @Configuration / @Bean wiring
```

**Graça ("Explicit Architecture"):**
- `Core/Component/<BC>/{Application,Domain}`
- `Core/Port/<ToolType>`
- `Infrastructure/<ToolType>/<Vendor>`
- `UserInterface/{Api,Cli,Web}`

**Go (Three Dots Labs, Wild Workouts):**
- Layout: `internal/<context>/{domain,app,adapters,ports}` plus `main.go`.
- ⚠ Here `ports/` holds *driving adapters* (HTTP/gRPC handlers) and `adapters/` holds driven adapters. Don't confuse this with Cockburn's vocabulary.
- Interfaces are declared in `app` (the consumer).

**Python (Cosmic Python):**
- Layout: `domain/`, `service_layer/{handlers,messagebus,unit_of_work}`, `adapters/{orm,repository,notifications}`, `entrypoints/`, `bootstrap.py`.
- Its abstractions sit next to their implementations. Move them inward if you want strict enforcement.

**Folder naming:** use `inbound`/`outbound`, or `driving`/`driven`, consistently. Cockburn prefers `inbound`/`outbound` for folders because `driving_adapters` and `driven_adapters` blur together.

## Naming

| Thing | Convention | Examples |
|---|---|---|
| Port (Cockburn) | `For<Verb-ing><Object>` | `ForParkingCars`, `ForObtainingRates` |
| Port (Hombergs) | `*UseCase` in, `*Port` out | `SendMoneyUseCase`, `LoadAccountPort` |
| Port (DDD/tool-flavoured) | `*Repository`, `*Gateway`, `*Publisher`, `Clock` | `OrderRepository`, `PaymentGateway` |
| Adapter | technology + purpose | `PostgresTicketStore`, `StripePayments`, `InMemoryTicketStore`, `FixedClock` |
| Command / input | imperative noun | `SendMoneyCommand`, `PlaceOrder` |

- **Pick one port convention per codebase.**
- **Never put a technology in a port name.**
- **Always put the technology in an adapter name.**

## Wiring (the configurator / composition root)

- **Hand-wired `main` is the default, and the clearest.**
  - Order: driven adapters → app → driving adapters → run.
  - In Go, constructors panic on nil dependencies.
- **Tests are their own composition roots.** Each test wires the app to fakes.
- **Spring, strict:**
  - No Spring annotations in `domain` or `application`.
  - Declare use cases as `@Bean`s in a config module, e.g. `@Bean SendMoneyUseCase sendMoney(LoadAccountPort l, UpdateAccountStatePort u) { return new SendMoneyService(l, u); }`.
  - Alternatively, annotate *packages* (not classes) with jMolecules stereotypes in `package-info.java`.
- **Spring, pragmatic (BuckPal):**
  - A custom `@UseCase` annotation, meta-annotated with `@Component`, plus `@Transactional` on the service.
  - The core then has a framework dependency. Accept it knowingly.
- **Python (Cosmic Python):**
  - A `bootstrap()` function takes production defaults that tests override.
  - Handlers receive their dependencies via closures, `functools.partial`, or signature introspection.
  - Seemann calls this "Pure DI".
- **TypeScript:**
  - Use factory functions that close over their dependencies.
  - Decorator-based DI containers (tsyringe, inversify) put decorators into the core. Avoid them inside, or confine them to the adapters.
- **.NET:**
  - Wire everything in the host's `Program.cs`.
  - Each adapter project exposes an `IServiceCollection` extension method, e.g. `AddPostgresPersistence()`.
- **Runtime adapter selection** (per tenant or country): use a broker or factory in the configurator, never in the core.

## Language idioms

**Go**
- Interfaces "belong in the package that uses values of the interface type". Return concrete types. "Do not define interfaces before they are used."
- Driven ports are small consumer-side interfaces in `app` or `domain`.
- The driving port is usually the concrete `app.Service` struct, or `Commands`/`Queries` structs.
- Implicit satisfaction means adapters never import a ports package. Pin conformance with:
  ```go
  var _ app.TicketStore = (*PostgresTicketStore)(nil)
  ```
- `internal/` gives compile-time boundaries for free.

**TypeScript**
- Structural typing means ports are `interface`/`type` declarations, or plain function types (`type Clock = () => Date`).
- Use `implements` or `satisfies` on adapters to get errors at the adapter.
- Import ports with `import type`, so they erase at runtime.

**Python**
- Define ports with `typing.Protocol` (structural) or `abc.ABC` (nominal, explicit). Cosmic Python's authors sometimes delete the ABCs in production.
- Invert the ORM with imperative mapping (`start_mappers()`), so the domain stays plain classes or dataclasses.
- The standard stack is Repository + Unit of Work + message bus (commands and events) + `bootstrap`.

**Java/Kotlin**
- Ports are interfaces in `port.in` / `port.out`. Commands are self-validating records.
- Kotlin `fun interface` suits single-method ports.
- Make adapter and service internals package-private (Kotlin: `internal`), so only ports are public.
- Use Gradle `implementation` (not `api`) so dependencies don't leak transitively.

**.NET**
- Project references are the boundary: `Domain` → none; `Application` → `Domain`; `Adapters.*` → `Application`; `Host` → all.

**Rust**
- Use a workspace with one crate per zone: `domain`, `app` (holds the port traits), `adapter-*`, and a `bin` crate as the configurator. Cargo forbids cycles between crates.
- Choose generics (`Service<R: TicketStore>`, static dispatch) or `Arc<dyn TicketStore>`.
- Async trait methods and `dyn` interact. Check the current state of `async fn` in traits for your toolchain, and use `async-trait` or boxed futures if you need `dyn`.

**Functional languages**
- First prefer passing values into a pure core (the impureim sandwich; see ADOPTION.md).
- When a port is needed, use a function type (`type LoadOrder = OrderId -> Async<Order option>`) or a record of functions (Haskell's "handle pattern", Elixir behaviours).
- Partial application is the DI mechanism.

## Testing strategy

1. **The test harness is the first driving adapter.** Write tests against driving ports before any UI exists (stages S1–S2 in CANON.md).
2. **Core tests run through the driving ports with in-memory driven adapters.**
   - Use fakes with state assertions, not mocks with call verification.
   - A recording fake (`sent: list`) covers recipient ports.
   - Cosmic Python's rule of thumb: "if an abstraction is hard to fake, it is probably too complicated."
3. **Run the same contract (role) test suite against the fake and the real adapter.** This is what keeps the fakes honest, and it's the step most teams skip.
   ```python
   class TicketStoreContract:                       # abstract, not collected
       def make_store(self): raise NotImplementedError
       def test_stored_ticket_is_found(self):
           s = self.make_store(); s.store(Ticket("t1")); assert s.find("t1").id == "t1"
       def test_missing_ticket_is_none(self):
           assert self.make_store().find("nope") is None
   class TestInMemoryTicketStore(TicketStoreContract):
       def make_store(self): return InMemoryTicketStore()
   class TestPostgresTicketStore(TicketStoreContract):   # integration-marked, Testcontainers
       def make_store(self): return PostgresTicketStore(pg_url)
   ```
   - Java: use an abstract test class with a factory method. RSpec: `shared_examples`. Go: a `func TestTicketStoreContract(t *testing.T, mk func() TicketStore)` helper.
   - Use a fresh instance per test.
   - Some behaviour only the real adapter has: isolation, constraints, migrations, query semantics. Keep a few real-only tests for it.
4. **Adapter integration tests:**
   - Driven adapters run against real infrastructure (Testcontainers).
   - Driving adapters get slice tests against a faked app port: is the HTTP mapping, status and serialization correct?
5. **A few end-to-end tests** through the real configurator. They exist to prove the wiring, which nothing else covers.
6. **Architecture tests run in the normal unit-test run** (see ENFORCEMENT.md).
7. **Alternative:** James Shore's Nullables, i.e. production adapters with a `createNull()` off-switch. Useful where maintaining separate fakes is costly.

## Adapter catalogue

**Driving adapters:**
- HTTP (REST, GraphQL, gRPC) controllers.
- CLI commands.
- Queue and stream consumers.
- Cron and scheduled jobs.
- Webhooks.
- Serverless handlers.
- Admin and configuration UIs (`ForConfiguringApp`).
- Other applications.
- **Test harnesses** (unit tests, Cucumber, FIT).

**Driven adapters:**
- Database repositories.
- Event and message publishers (via outbox).
- Email, SMS and push notifiers.
- Payment and other third-party APIs.
- File and object storage.
- Search engines.
- **Clock, ID generator, random source.**
- Feature flags.
- External identity and permissions services.

**Each driven port should have:**
- a production adapter;
- a fake (in-memory, fixed, or recording);
- a shared contract suite.
