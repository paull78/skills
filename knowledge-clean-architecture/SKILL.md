---
name: knowledge-clean-architecture
description: Architecture knowledge from Robert C. Martin's Clean Architecture and SOLID principles. Use as a grilling lens when evaluating designs for dependency management, separation of concerns, and component boundaries.
---

# Clean Architecture — Robert C. Martin

## SOLID Principles

- **Single Responsibility:** Each module has one reason to change — one actor it serves.
- **Open-Closed:** Extend behavior without modifying existing code. New features = new code, not changed code.
- **Liskov Substitution:** Subtypes must be substitutable for their base types without breaking callers.
- **Interface Segregation:** No client should depend on methods it doesn't use. Prefer narrow, role-specific interfaces.
- **Dependency Inversion:** High-level policy must not depend on low-level detail. Both depend on abstractions.

## The Dependency Rule

- Source code dependencies point inward — toward higher-level policies.
- Inner circles know nothing about outer circles. No name from an outer circle may appear in an inner one.
- Concentric layers: Entities → Use Cases → Interface Adapters → Frameworks/Drivers.

## Component Principles

- **Cohesion:** group by reason-to-change, not by technical layer.
- **Coupling:** depend in the direction of stability. Stable components should be abstract.
- **Acyclic Dependencies:** no cycles in the component dependency graph.

## Key Anti-Patterns

- Business logic importing framework types.
- Use cases aware of delivery mechanism (HTTP, CLI, queue).
- Database schema driving domain model shape.
- Shared mutable state crossing boundaries.
- "God" modules with multiple reasons to change.

## Grilling Questions

- Where does this dependency point — toward policy or toward detail?
- If the database changes, what breaks?
- If the UI changes, what breaks?
- Can you test the business rules without the framework running?
- Which actor owns this module's reason to change?
