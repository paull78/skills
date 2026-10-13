# Canon: what the primary sources actually say

Sources:
- Cockburn, "Hexagonal Architecture" (HaT Technical Report 2005.02).
- Cockburn & Garrido de Paz, *Hexagonal Architecture Explained*: preview edition May 2024; updated 1st edition April 2025.
- Cockburn's 2023 and 2025 slides.
- Cockburn's 2017 FAQ.
- Garrido de Paz's articles at jmgarridopaz.github.io.

## Origin and motivation

- **The original problem was business logic leaking into UI code.** That made the app:
  - impossible to test automatically, because tests were coupled to "field size and button placement";
  - impossible to run in batch;
  - impossible to drive from another program.
- **The usual fix doesn't work.** Adding a layer and promising to keep logic out of it fails, because there is "no mechanism to detect when a violation of that promise occurs". In P&A, the regression tests through the ports *are* that mechanism.
- **The database side has the mirror problem.** When the database is down or being reworked, "the programmers can't work".
- **The asymmetry that matters is inside versus outside, not left versus right.**
- **The headline demand (book §1.1):** "Create your application to work without either a UI or a database so you can run automated regression-tests against it, change connected technologies, protect it from leaks between business logic and technologies, work when the database becomes unavailable, and link applications together without any user involvement."
- **The most surprising requirement:** "Never explicitly name any external object or technology. Always take a parameter for any external object or technology you wish to access."
- **Why a hexagon:** it leaves drawing room for ports and breaks the reflex of drawing the user on top and the database at the bottom. "Pentagons and heptagons are impossible to draw … That's all."
- **Cockburn's own summary of the pattern** is a colleague's line: "Give me API or give me death."

## Elements

| Element | Meaning |
|---|---|
| App / hexagon / core / SuD | The business logic, with no reference to any technology. These names are synonyms. |
| Actor | Anything with behaviour outside the app. Primary/driving actors initiate; secondary/driven actors are called by the app. |
| Port | A purposeful conversation. The app owns its interface. A driving port is the *provided* interface (API); a driven port is the *required* interface (SPI). A port can have several functions. |
| Adapter | Converts between a port and a specific technology. A port typically has several adapters. |
| Configurator | Officially outside the pattern, but every implementation needs one: the composition root that "knows all the players and introduces them to each other". |

- **Terminology.**
  - Only *driving/driven* and *primary/secondary* apply cleanly to actors, ports and adapters alike. Nobody says "inbound actor".
  - *Inbound/outbound* suit folder names, because "driving_adapters" and "driven_adapters" look too alike side by side.
  - Garrido de Paz uses *driver/driven*. Driven actors come in two kinds: **repository** (round trip, "boomerang") and **recipient** ("shoot and forget").
- **The correct flow is** Actor → Adapter → (Port) App. Drawings that show Actor → Port → Adapter are wrong.

## Naming ports

- **The convention is "For + verb-ing + object".**
  - Book examples: `ForCalculatingTaxes`, `ForGettingTaxRates`.
  - BlueZone examples: `ForParkingCars`, `ForCheckingCars`, `ForObtainingRates`, `ForStoringTickets`, `ForPaying`, `ForConfiguringApp`.
  - Paris 2017 examples: "For selecting a drink", "For obtaining prices & recipes", "For dispensing".
- **Typical port families:** for configuring, for using, for notifying, for getting data, for admin, for controlling something.
- **Exact naming and coding style are "not part of the pattern".** Purpose-naming *is* the point.
  - Cockburn's known use: a weather system was fixed by architecting interfaces "*by purpose* rather than by technology".

## Canonical minimal code

```java
// driving port: provided by app
interface ForCalculatingTaxes { double taxOn(double amount); }
// driven port: required by app
interface ForGettingTaxRates  { double taxRate(double amount); }

class TaxCalculator implements ForCalculatingTaxes {
  private final ForGettingTaxRates rates;
  TaxCalculator(ForGettingTaxRates rates) { this.rates = rates; }
  public double taxOn(double amount) { return amount * rates.taxRate(amount); }
}
class FixedTaxRateRepository implements ForGettingTaxRates {    // test/stub adapter
  public double taxRate(double amount) { return 0.15; }
}
class Main {                                                     // the configurator
  public static void main(String[] a) {
    ForCalculatingTaxes app = new TaxCalculator(new FixedTaxRateRepository());
  }
}
```

- **The 2025 edition corrects the preview.** The preview typed `TaxCalculator myCalculator` with the class instead of the interface, which Cockburn now calls "almost humorously wrong". There are two valid schools:
  - (a) declare the driving interface and use it everywhere;
  - (b) declare no driving interface, because the app's public methods are the port.
  
  Mixing the two is the error.
- **Dynamic languages** such as Ruby declare no port interfaces at all.

## How many ports

- **2005:** "largely a matter of taste". One port per use case would mean hundreds; one big port would mean two. "Neither extreme appears optimal." Two to four was typical then.
- **Book:**
  - Start with one port per primary or secondary actor.
  - Splitting further brings "a rapid increase in complexity and decrease in value".
  - Expect at least two driving ports and "unlikely more than seven or eight driven" ones.
  - Different actor roles with different permissions (manager vs clerk) can justify separate driving ports.
- **Garrido de Paz:** "Make a driven port for an external system, not for a domain concept". An external system is one whose interface your team can't change.
- **Cockburn's #1 observed error:** "using only one technology per port, or port per technology, when the whole point of a port is to allow technology substitutions."

## Development sequence ("tests + mocks first")

Garrido de Paz's five stages, from Cockburn at Agiles 2020:

| Stage | Driver side | App | Driven side |
|---|---|---|---|
| S1 | test cases | hard-coded response | — |
| S2 | test cases | real | test doubles |
| S3 | real UI/API | real | test doubles |
| S4 | test cases | real | real |
| S5 | real | real | real |

- **"After S2, the hexagon is done."** This is a walking skeleton, and the full business logic need not exist yet.
- **"The test case is the first user."** Each test case acts as its own configurator.

## The configurator

- The configurator is where source dependencies concentrate: "That's where source-code dependencies lie."
- **Two options:**
  - The configurator tells the app which receivers to use (dependency injection).
  - The app asks a broker (dependency lookup, or service locator), e.g. to pick an adapter per country at runtime.
- **Underlying pattern:**
  - Old name: "Configurable Dependency" (Meszaros/Cockburn, around 2011–2012). This is not in the 2005 article, which points to DIP/DI.
  - 2023 name: **Configurable Receiver**, which subsumes DI and dependency lookup.
  - Hexagonal is "a double application" of it: once for drivers, and once for each repository and recipient.
- **Runtime swapping of driven actors** can leave the app inconsistent mid-reconfiguration. Design for that if you allow it.
- **Order of construction (Garrido de Paz):**
  1. driven adapters;
  2. the app, with the driven adapters injected;
  3. driver adapters, with the app injected;
  4. run.

## Costs Cockburn admits (2023 slides)

1. An instance variable for each driven actor.
2. A constructor parameter or setter for each one.
3. A configurator to design.
4. Declared required interfaces, in typed languages.
5. Folders for port declarations.

- "This pattern trades complexity for flexibility."
- "If you put Configurable Receivers everywhere, your code becomes unnecessarily cluttered."
- Garrido de Paz on small projects: "the cure is worse than the disease."

## Relation to other architectures (Cockburn's statements)

- **Layered/Onion/Clean (book §5.5).** P&A differs in two ways:
  - it has "only two layers: the inside … and the outside";
  - it "requires that you organize the external actors so they connect to specific ports".
- **Onion and Clean "have the same dependency structure"**, but they don't require ports and they add inner layers. "Once you have implemented Ports & Adapters, you are welcome to add the layers of clean and onion – or not."
- **Layered → hexagonal in two steps:**
  1. Invert the dependencies.
  2. Make sure the ports are defined inside the app.
- **DDD.**
  - Hexagonal is "a preamble to DDD … like cleaning the kitchen". DDD people adopted it as "an act of self-defense" around the domain model.
  - A bounded context *may* have ports, but not every bounded context is P&A.
  - DDD's anti-corruption layer is broader than a P&A adapter.
- **Translation placement (Garrido de Paz, "The right boundary").**
  - ACL-style model translation (external concepts → domain concepts) belongs *inside* the hexagon: Hexagon = Domain + ACL logic + driven port.
  - The adapter does only *technology* translation.
  - "Splitting the hexagon into application layer and domain … is a DDD thing … not a hexagonal architecture issue."
- **CQRS** can be built with P&A, but is not inherently P&A. Cockburn: "CQRS is a right-side … conversation"; "microservices is a left-side conversation".
- **MVC and its variants** implement P&A *only on the driving side*.
- **James Grenning's embedded architecture** is "the exact same architecture… different words": his "Service Abstraction Layer" equals the driven adapters.
- **P&A is a special case of Component + Strategy**, where the boundary sits "just in front of external technologies". If interfaces already match, no adapter is needed.
- **Hexagons don't nest.** A network of hexagons is fine; a hexagon drawn inside a hexagon is a misreading.

## Asymmetry

- **The concept is symmetric. The implementation isn't.**
  - The app never knows who drives it.
  - The app must hold references to whatever it drives.
- Cockburn: "most people focus on left side. I got hurt more by right side absence."
- Batch jobs are legitimate drivers, which Cockburn found hard to get people to accept back in 1994.

## Common misreadings to correct

- "Hexagonal = domain/application/infrastructure layers." No: it has two zones.
- "Hexagonal requires DDD." No: the inside may be a transaction script, a CRUD layer or a ball of mud.
- "Port = class" or "port = one method". No: a port is a purposeful conversation, and it may have many functions.
- "One port per technology." This is the #1 error, because it defeats substitution.
- "Ports live with their adapters." No: the app owns them.
- "Six sides means six ports." No.
- "Hexagon done = layers drawn." No: with no test adapters on both sides, it isn't hexagonal.
- "It exists so we can swap databases." It mainly exists for isolation and test automation; swapping technology is a side benefit.
