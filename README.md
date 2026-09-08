# Designing and Building a High-Scale PHP Content Management System

**3 full lessons from this course are free to read — no signup, no card.** This repository holds the working code for those lessons.

[![Free lessons](https://img.shields.io/badge/free_lessons-3-16703E?style=flat-square)](https://systemdrd.com/courses/hands-on-php-programming-course/?utm_source=github&utm_medium=readme&utm_campaign=php-content-management-system) [![Course](https://img.shields.io/badge/full_course-90_lessons-D92B21?style=flat-square)](https://systemdrd.com/courses/hands-on-php-programming-course/?utm_source=github&utm_medium=readme&utm_campaign=php-content-management-system) [![Topic](https://img.shields.io/badge/Backend_Engineering-informational?style=flat-square)](https://systemdrd.com/courses/hands-on-php-programming-course/?utm_source=github&utm_medium=readme&utm_campaign=php-content-management-system)

## Start with the free lessons

Each lesson is the same one a paying subscriber reads — the full text, not a preview. The code for it is in this repository.

| | Read the lesson | Code in this repo |
|---|---|---|
| **Day 1** | [Benchmarking the “Bootload Tax”: FPM vs. Persistent Workers.](https://systemdrd.com/lessons/system-design-worker-optimization/?utm_source=github&utm_medium=readme&utm_campaign=php-content-management-system) | [`day1/`](day1) |
| **Day 2** | [Configuring RoadRunner: The `rr.yaml` supervisor setup.](https://systemdrd.com/lessons/roadrunner-supervisor-yaml/?utm_source=github&utm_medium=readme&utm_campaign=php-content-management-system) | [`day2/`](day2) |
| **Day 3** | [Writing the Worker Loop: Managing the Goridge protocol.](https://systemdrd.com/lessons/goridge-worker-loop-design/?utm_source=github&utm_medium=readme&utm_campaign=php-content-management-system) | [`day3/`](day3) |

## The rest of the course — 90 lessons

<details><summary>Full curriculum (90 lessons)</summary>

- Day 1: Benchmarking the “Bootload Tax”: FPM vs. Persistent Workers. — **free, above**
- Day 2: Configuring RoadRunner: The `rr.yaml` supervisor setup. — **free, above**
- Day 3: Writing the Worker Loop: Managing the Goridge protocol. — **free, above**
- Day 4: State Safety: Analyzing static memory in long-living processes.
- Day 5: Memory Leak Detection: Using `gc_collect_cycles()` and memory profiling.
- Day 6: OPcache Optimization: Enabling JIT and `opcache.enable_cli`.
- Day 7: Resource Cleanup: Implementing safe `__destruct` patterns.
- Day 8: Signal Handling: Managing graceful reloads for zero-downtime.
- Day 9: Scaling with FrankenPHP: Implementing Caddy-based PHP runners.
- Day 10: The Kernel Registry: Bootstrapping application state once per lifecycle.
- Day11: PSR-7 Implementation: Building immutable HTTP messages.
- Day12 : The Prefix-Tree Router: route matching logic.
- Day13: Attribute-Based Discovery: Using PHP 8 Attributes for routing.
- Day14: PSR-15 Middleware: Implementing the modular request pipeline.
- Day15: Context Propagation: Managing request metadata without global state.
- Day16: Exception Interception: Converting errors into structured responses.
- Day17: Declarative Sanitization: Building high-frequency input validators.
- Day18: Payload Streaming: Handling large responses using PSR-7 streams.
- Day19: Multi-format Negotiation: Implementing the `Accept` header logic.
- Day20: Edge Rate Limiting: Building token-bucket middleware.
- Day21:The EAV Paradigm: Building flexible attribute tables.
- Day22: PostgreSQL JSONB: Efficient metadata storage patterns.
- Day 23: Hybrid Modeling: Combining indexed EAV with JSONB blobs.
- Day 24 : Index Optimization: Implementing GIN and expression indexes.
- Day 25 : Batch Hydration: Solving the problem for dynamic fields.
- Day 26: Connection Pooling: Persistent DB links in worker pools.
- Day 27: Sharding Strategies: Implementing range vs. hash partitioning.
- Day 28: ACID vs. Scale: Transaction isolation trade-offs.
- Day 29: The Repository Pattern: Decoupling storage from core logic.
- Day 30 : Content Versioning: Managing history without read degradation.
- Day 31: Metadata Discovery: Scanning namespaces for plugins.
- Day 32: Building PSR-11: Implementing a DI container from scratch.
- Day 33: Autowiring: Resolving dependencies using Reflection.
- Day 34: PHP 8.4 Lazy Objects: Deferring expensive service initialization.
- Day 35: Dependency DAG: Resolving plugin loading order.
- Day 36: Service Providers: Implementing the “register/boot” lifecycle.
- Day 37: Config Merging: Allowing plugins to expose dynamic settings.
- Day 38: Interface Contracts: Ensuring stability with strict types.
- Day 39: Anti-Pattern Defense: Eliminating the Service Locator.
- Day 40: Circular Detection: Implementing recursive dependency checks.
- Day 41: PSR-14 Dispatching: Building the decoupled handler system.
- Day 42: Async Offloading: Moving events to background job queues.
- Day 43: Priority Listeners: Managing the event execution chain.
- Day 44: Propagation Control: Implementing `stopPropagation` logic.
- Day 45: Event Mapping: Using `#[AsEventListener]` for registration.
- Day 46: Domain Events: Dispatching `PostCreated` from the storage layer.
- Day 47: Event Auditing: Tracking the request-event lifecycle.
- Day 48: Redis Pub/Sub: Cross-worker event broadcasting.
- Day 49: Listener Isolation: Preventing handler failures from crashing the core.
- Day 50: Testing Events: Unit testing decoupled workflows.
- Day 51: Lexical Analysis: Tokenizing template syntax.
- Day 52: The Parser: Transforming tokens into an AST.
- Day 53: AST Compiler: Pruning trees for optimized output.
- Day 54: Code Generation: Compiling templates to cached PHP classes.
- Day 55: Security Sandboxing: Implementing capability-based restrictions.
- Day 56: Contextual Escaping: Automated XSS protection.
- Day 57: Template Inheritance: Implementing block/extends logic.
- Day 58: Custom DSL: Allowing plugins to add tags and filters.
- Day 59: Multi-layer Caching: Balancing disk and memory storage.
- Day 60: AST Visualization: Building debugging tools for compilers.
- Day 61: Caching Hierarchy: L1 (Local), L2 (Redis), L3 (Varnish).
- Day 62: Consistent Hashing: Implementing a hash ring for clusters.
- Day 63: Stampede Protection: The “Lease” and locking mechanism.
- Day 64: Tag-Based Invalidation: Grouping related cache keys.
- Day 65: Varnish & ESI: Hybrid caching for dynamic fragments.
- Day 66: Consistency Patterns: Write-through vs. write-behind.
- Day 67: The Gutter Pool: Handling server failure with fallback nodes.
- Day 68: Probabilistic Eviction: Managing memory limits at scale.
- Day 69: Session Scaling: Implementing Redis-backed persistent sessions.
- Day 70: Cache Warming: Pre-populating high-traffic content.
- …and 20 more

</details>

## Get the whole course

**$99 one-off.** No subscription.

- All 90 lessons, written to the same depth as the 3 free ones above
- The complete source repository, one commit per lesson, beyond the 3 lessons here
- Every later lesson builds on the code in this repo, so nothing is thrown away

### [Read the free lessons first →](https://systemdrd.com/courses/hands-on-php-programming-course/?utm_source=github&utm_medium=readme&utm_campaign=php-content-management-system)

---

Part of [SystemDR](https://systemdrd.com/courses/?utm_source=github&utm_medium=readme&utm_campaign=php-content-management-system) — hands-on engineering courses where you build the system, break it, and fix it. [All courses](https://systemdrd.com/courses/?utm_source=github&utm_medium=readme&utm_campaign=php-content-management-system) · [Free lessons across every course](https://systemdrd.com/trial-lessons/?utm_source=github&utm_medium=readme&utm_campaign=php-content-management-system)
