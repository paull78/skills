# Pitfalls: symptom → why it hurts → fix

## 1. Ports shaped after the technology
- **Symptom:** signatures like these:
  - `executeQuery(sql)` or `findBySpecification(Specification<T>)`;
  - `Pageable` / `Page<T>`;
  - a port that returns a JPA entity, a `ResultSet` or a vendor SDK type;
  - `SQLException`, `HttpClientErrorException` or `AmazonServiceException` escaping through the port;
  - a port named `S3Port`, `KafkaPort` or `SqlPort`.
- **Why it hurts:**
  - The core now encodes the adapter's protocol.
  - A fake has to reimplement a vendor API.
  - Swapping vendors touches the core.
  - This is "weak conformance": legal in the letter of the pattern, but it defeats the purpose.
- **Fix:**
  - Ports "fit the Application Core needs and not simply mimic the tools APIs" (Graça).
  - Use core-owned value types (`PageRequest`, `SortKey` enum, filter objects) and a core-owned error set.
  - The adapter translates in both directions.

## 2. Port per technology / one adapter per port
- **Symptom:** `PostgresPort` and `RedisPort`, each with a single implementation and no test adapter.
- **Why it hurts:** Cockburn calls this the #1 error. A port exists to allow substitution. With one technology per port, the port can't substitute anything.
- **Fix:**
  - Name the port by purpose (`ForStoringTickets`).
  - Give each port at least a real adapter and a test adapter from the start.

## 3. Ports owned by the wrong side
- **Symptom:**
  - The interface lives in `infrastructure/persistence` or inside the adapter module.
  - Or the core imports an adapter's DTO.
- **Why it hurts:** The dependency arrow points outward again, so the "inversion" is cosmetic.
- **Fix:**
  - Port declarations live in the app, typically `application/port/{in,out}` or `ports/driving|driven/for…`.
  - Enforce this with an architecture test (see ENFORCEMENT.md).
- **Watch out for Cosmic Python's pragmatic layout.** It co-locates `AbstractRepository` with `SqlAlchemyRepository`, and a strict import-linter contract fails on that. Move the abstractions inward if you enforce.

## 4. Interface-per-class ceremony
- **Symptom:**
  - `IFooService` / `FooServiceImpl` pairs.
  - A `SendMoneyUseCase` interface with exactly one implementation.
  - Interfaces declared "so we can mock it".
- **Why it hurts:**
  - Every navigation goes through an extra hop, and there are twice as many files.
  - Seemann: "interfaces are not abstractions". A 1:1 interface and class breaks the Reused Abstractions Principle.
  - Rentea: "Question any interface with a single implementation, in the same module."
- **Fix:** Keep an interface only if one of these holds:
  - (a) it inverts a dependency, which is true of every driven port;
  - (b) it has more than one real implementation. Test fakes count, and every driven port should have one;
  - (c) it's published to clients.
  
  Driving ports can usually be the concrete service's public API (Cockburn's second "school").
- **Go:** don't declare an interface next to its implementation. Declare it in the consumer.

## 5. Business logic drifting into adapters
- **Symptom:**
  - Controllers orchestrate several calls, check business rules, decide what to save, or pick between use cases.
  - Persistence adapters contain `if` statements about domain state.
  - Message consumers contain workflow logic.
- **Why it hurts:**
  - The logic can't be tested without the framework.
  - It gets duplicated as soon as a second driver arrives (CLI, queue, batch).
  - Cockburn: "A common mistake is to write use cases to contain intimate knowledge of the technology sitting outside each port."
- **Fix:** Split validation by kind:
  - **Syntactic or shape validation** (non-null, format, parseable) goes in the adapter or in a self-validating command object.
  - **Semantic, state-dependent rules** ("balance sufficient", "seat still free") go inside.
  - An adapter's whole job is to parse, call one port operation, then map the result or error.

## 6. Adapters calling adapters
- **Symptom:**
  - A controller calls the repository directly.
  - A Kafka listener calls the REST client.
  - A persistence adapter publishes events itself.
- **Why it hurts:** It bypasses the rules, creates hidden coupling, and the test harness can't see the behaviour.
- **Fix:**
  - All traffic goes through the inside, even when the inside is a pass-through.
  - If that pass-through feels like pure ceremony, the feature probably doesn't need a hexagon (see ADOPTION.md).
  - Adapter modules must not be able to see each other: use package-private visibility or separate build modules.

## 7. Framework-annotated domain ("leaky entities")
- **Symptom:**
  - `@Entity`, `@Column`, `@JsonProperty`, `@Valid`, `@Service`, `@Transactional` or Pydantic models in the domain.
  - A no-arg constructor plus setters, forced by the ORM.
- **Why it hurts:**
  - One class serves three masters: domain, persistence and JSON.
  - A schema change becomes a domain change.
  - Invariants can be bypassed through setters.
  - Serializing the domain directly can leak sensitive fields.
- **Fix:**
  - Give adapters their own models where the shapes diverge (see the mapping strategies in HARD-PROBLEMS.md).
  - Python: use imperative/classical ORM mapping, so "the ORM imports the domain model, not the other way around".
- **Legitimate counter-position (Rentea):**
  - One annotated model is often cheaper than 4× the CRUD code.
  - If you choose it, choose it consciously, learn the ORM well, and watch the generated SQL.

## 8. Generic CRUD repository port
- **Symptom:** a `Repository<T, ID>` with `save`, `findAll`, `delete` and an ever-growing family of `findByXAndY`.
- **Why it hurts:**
  - It exposes operations no use case needs, such as `delete` on an aggregate that must never be deleted.
  - Query logic creeps into the core.
  - The fakes grow huge.
- **Fix:** Use a consumer-shaped port with only the operations the app needs, phrased in domain language. Then pick one granularity convention:
  - **Coarse:** a port per external system (Cockburn/Garrido).
  - **Per aggregate:** DDD.
  - **Narrow per use-case need:** Hombergs (`LoadAccountPort`, `UpdateAccountStatePort`), one adapter implementing several ports.

## 9. Over-layering the inside
- **Symptom:** `Controller → InputPort → UseCase → DomainService → OutputPort → Adapter → Mapper → JpaRepository`, all for a one-line read.
- **Why it hurts:** You get "Middle Man" indirection without abstraction (Rentea). Noback calls it "lasagna code: if it hurts, maybe you shouldn't do it."
- **Fix:**
  - The pattern only demands inside versus outside. Relax the inner layering.
  - Let reads take a short path (see "Read side" in HARD-PROBLEMS.md).

## 10. Mocking everything
- **Symptom:**
  - Every use-case test stubs five ports and verifies call order.
  - Refactors break tests even though behaviour didn't change.
  - Test code is 5× the size of the production code.
- **Why it hurts:**
  - The tests pin the implementation, not the behaviour.
  - A mock of your own database proves nothing about queries, mappings or constraints.
- **Fix:**
  - Use in-memory **fakes** with state assertions, plus a **contract suite** run against both the fake and the real adapter.
  - Use mocks only for recipient-style interactions where "was it sent?" *is* the behaviour, and even then a recording fake (`sent = []`) is usually better.
  - "Don't mock types you don't own." Wrap the SDK in your own port and integration-test the wrapper.
  - Khorikov's position: mocks are for communication with *external* systems. For a database only your app owns, real-DB integration tests are often worth more than a port plus mock.

## 11. Anemic domain behind beautiful ports
- **Symptom:** Entities are getters and setters, and every rule lives in `*UseCase` classes.
- **Why it's subtle:**
  - This is *legal* hexagonal, because the inside is unconstrained.
  - You still get isolation and testability.
  - Just don't call it DDD, and don't expect DDD's benefits.
- **Fix:** Only fix it if domain complexity warrants it. Move invariants into entities and value objects as the rules grow.

## 12. Premature hexagon
- **Symptom:** ports, mappers and four model classes for a forms-over-tables app or a thin ETL pipe.
- **Why it hurts:** You pay all the cost and get none of the benefit. Hombergs: for CRUD "an architecture like this is probably overhead".
- **Fix:** Use vertical slices, transaction scripts or plain layering. Apply hex *per module* where the rules or volatile integrations actually are.

## 13. No enforcement
- **Symptom:** The architecture exists in a wiki diagram. Six months later, `domain` imports `sqlalchemy`.
- **Why it hurts:** This is exactly the failure Cockburn described for layers: no mechanism detects the violation. Seemann calls OO hexagonal "a Sisyphean task" without enforcement.
- **Fix:** Add an architecture test in the normal test run on day one (see ENFORCEMENT.md).

## 14. Half-applied hexagon
- **Symptom:** Some features go through ports, others reach the database from controllers, and there's no rule for which is which.
- **Why it hurts:** Readers can't predict where logic lives. It is worse than an honest layered app.
- **Fix:** Make an explicit, written decision about which modules are hexagonal, and enforce it per module.

## 15. Lying about swappability
- **Symptom:** The ports assume capabilities only one technology provides (full-text search, transactions across aggregates, server-side joins), yet the design claims the database is swappable.
- **Why it hurts:** Graham Cox: "the choice of infrastructure defines the ports". A second technology forces extra ports or double queries.
- **Fix:**
  - Be honest: ports encode the *capabilities you depend on*.
  - Swappability is bounded by those capabilities.
  - Justify the hexagon by isolation and testability, not by a hypothetical database migration.

## 16. Unenforced configurator sprawl
- **Symptom:** Wiring is scattered: framework autoscan, `new` calls inside services, service locators called from domain code.
- **Why it hurts:** The source dependencies no longer concentrate in one place, and the core secretly knows its adapters.
- **Fix:**
  - Use one composition root per deployable, with tests as their own composition roots.
  - Never let the core call a container or locator.
