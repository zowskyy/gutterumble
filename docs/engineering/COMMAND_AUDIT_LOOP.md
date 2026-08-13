# GUTTERUMBLE — Command Audit + Debug Loop

**Applies to:** Commands 01–16 (and all slices under them)  
**Authority:** [`REPOSITORY_AUDIT.md`](./REPOSITORY_AUDIT.md), [`CANONICAL_ARCHITECTURE.md`](./CANONICAL_ARCHITECTURE.md), [`IMPLEMENTATION_DEPENDENCY_GRAPH.md`](./IMPLEMENTATION_DEPENDENCY_GRAPH.md)

No command advances because its code exists. It advances only when its acceptance criteria pass, its regression suite passes, and its architectural state is updated.

---

## Mandatory loop (every slice)

```
INSPECT → REPRODUCE → TRACE → CLASSIFY → PATCH → TEST → REGRESSION → AUDIT → DOCUMENT → GATE
```

### INSPECT

Read the relevant files completely. Search all references, callers, signals, RPCs, autoloads, scenes, resources, SQL, and configuration. **Do not modify code yet.**

### REPRODUCE

Establish current behavior before changing it. Record whether the problem is: reproducible, intermittent, environment-dependent, or currently **UNVERIFIED**.

### TRACE

Follow the complete execution path:

| Domain | Path |
|--------|------|
| Gameplay | Input → Controller → FSM → Combat → Hitbox/Hurtbox → Result → Presentation |
| Networking | Input → Client → ENet → Server → Simulation → Snapshot/Event → Client |
| Backend | Client → Auth → API/RPC → Database → Response |
| Android | Touch/Controller → InputCommand → Gameplay |

### CLASSIFY

Every finding must be one of:

- `BUG`
- `ARCHITECTURAL_DUPLICATION`
- `INTEGRATION_FAILURE`
- `SECURITY_FAILURE`
- `PERFORMANCE_FAILURE`
- `CONFIGURATION_FAILURE`
- `DEAD_CODE`
- `DOCUMENTATION_DRIFT`
- `UNVERIFIED`

Do not treat architectural forks as ordinary bugs.

### PATCH

Smallest change that fixes the **root cause**. Do **not**: create parallel implementations; add endless compatibility layers; duplicate gameplay rules; bypass canonical architecture; weaken tests to make them pass.

### TEST

Narrowest relevant test first, then: unit → subsystem → integration → gameplay → full regression.

### REGRESSION

Minimum categories that must remain green when touched:

player movement · light combo · heavy · dodge · stagger · knockback · special · enemy AI · waves · round completion · results · save/load · Android input · authentication · networking (when in scope)

### AUDIT

Re-search after the change for: stale references, duplicate implementations, obsolete RPCs, unreachable code, unused dependencies, mismatched schemas, docs describing the old architecture, **new architectural forks**.

### DOCUMENT

Update living docs immediately when architecture/risk changes:

- `PROJECT_STATE.md` (minimum)
- `CANONICAL_ARCHITECTURE.md` / migration plan when classification changes
- Android / backend / network docs when those surfaces change

### GATE

Each command ends with this block (fill every field):

```
COMMAND GATE
Implementation: [PASS/FAIL/UNVERIFIED]
Integration: [PASS/FAIL/UNVERIFIED]
Regression: [PASS/FAIL/UNVERIFIED]
Architecture: [PASS/FAIL/UNVERIFIED]
Security: [PASS/FAIL/UNVERIFIED/N/A]
Documentation: [PASS/FAIL]
Unresolved defects: […]
New risks: […]
Files changed: […]
Tests executed: […]
Next command permitted: YES / NO
```

**`Next command permitted: YES` only if** Implementation + Integration + Regression + Architecture are PASS (or N/A where applicable), Documentation is PASS, and unresolved defects do not block the next gate in [`IMPLEMENTATION_DEPENDENCY_GRAPH.md`](./IMPLEMENTATION_DEPENDENCY_GRAPH.md).

Status meanings:

| Status | Meaning |
|--------|---------|
| **PASS** | Implemented **and** successfully validated |
| **FAIL** | Known validation failure |
| **UNVERIFIED** | Cannot currently be tested |

**Never convert UNVERIFIED to PASS** because the implementation “looks correct.”

---

## Debug escalation (AEF-style)

If the **same attempted fix fails twice**, stop modifying that implementation path:

```
STOP → REVERT/ISOLATE → REASSESS ROOT CAUSE → SEARCH FOR ALTERNATIVE ARCHITECTURE → IMPLEMENT NEW APPROACH
```

Especially for: networking, Godot Android export, Supabase auth, synchronization.

---

## Global stop conditions

Stop feature building and return to audit when encountering:

- contradictory canonical implementations
- failing existing combat regression
- database schema/code mismatch
- server/client authority ambiguity
- authentication failure
- inability to establish a two-client server connection
- deterministic simulation divergence
- unreproducible networking bugs
- Android lifecycle crashes
- unexplained performance regression
- security validation failure
- tests modified solely to accommodate broken behavior

---

## Development gates (hard sequence)

```
GATE 0  Repository forensic inspection
GATE 1  Canonical architecture frozen
GATE 2  Offline Android game works
GATE 3  Supabase schema/authentication coherent
GATE 4  Dedicated server accepts two clients
GATE 5  Two clients move together authoritatively
GATE 6  Two clients fight the same enemy with server-authoritative combat
GATE 7  Revive + AI + weapons work online
GATE 8  Waves + boss work online
GATE 9  Matchmaking works
GATE 10 Android multiplayer works
GATE 11 5v5-scale profiling passes
GATE 12 Security audit passes
GATE 13 Content completion
GATE 14 100-pass release audit
```

**Multiplayer proof point (required before substantial arena/content production):**

> Two independently connected clients successfully execute the **canonical** combat system against the same authoritative server, with server-owned hit detection and results, and the existing offline combat regression suite remains passing.

Do **not** claim “multiplayer complete” without that proof.
