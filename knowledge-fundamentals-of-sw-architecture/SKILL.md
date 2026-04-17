---
name: knowledge-fundamentals-of-sw-architecture
description: Architecture knowledge from Richards & Ford's "Fundamentals of Software Architecture." Use as a challenge lens when evaluating architecture characteristics, component design, topology choices, and fitness functions.
---

# Fundamentals of Software Architecture — Richards & Ford

## Architecture Characteristics

Architecture is not just structure — it's the "-ilities" the system must support. Identify and prioritize:

- **Operational:** availability, scalability, performance, reliability, elasticity
- **Structural:** modularity, extensibility, maintainability, portability
- **Cross-cutting:** security, observability, testability, deployability

Rule: support at most 3-5 primary characteristics. More means none are truly prioritized.

## Laws of Software Architecture

1. Everything in software architecture is a tradeoff.
2. "Why" is more important than "how."
3. Architecture is the stuff that's hard to change later.

## Component Design

- **Cohesion:** components should have high functional cohesion — everything inside relates to one purpose.
- **Coupling:** minimize afferent (incoming) and efferent (outgoing) coupling. Measure instability = efferent / (afferent + efferent).
- **Connascence:** two components are connascent if changing one requires changing the other. Prefer static (compile-time) over dynamic (runtime) connascence. Minimize strength, reduce scope.

## Architecture Topology Selection

Choose topology based on characteristics, not fashion:

| Need | Consider |
|------|----------|
| Simplicity, speed to market | Monolith (layered/modular) |
| Independent deployability | Microservices |
| Event-driven workflows | Event-driven architecture |
| Mixed concerns | Service-based (pragmatic middle ground) |

## Fitness Functions

- Automated checks that validate architecture characteristics over time.
- Examples: dependency direction tests, performance budgets, cyclic dependency detection, deployment frequency metrics.
- Architecture without fitness functions will erode.

## Challenge Questions

- What are the top 3 architecture characteristics this system must support? Are you trying to support too many?
- What tradeoff are you making with this choice, and is it explicit?
- How will you know if this architecture degrades over time? Where are the fitness functions?
- Why this topology over the alternatives?
- What's the connascence between these components — static or dynamic?
