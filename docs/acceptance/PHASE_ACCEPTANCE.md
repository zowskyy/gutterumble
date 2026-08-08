# Phase Acceptance Checkpoints

Validation-only slices from the Public Release Roadmap. Mark `VERIFIED` in `TRACKING.json` only after steps below are executed — not on code-complete alone.

## Phase 0.5 — Solo Core Loop

- [ ] 3 independent playtesters, 10 minutes solo each (no network)
- [ ] Each rates "would I play this again" — net positive required
- [ ] Document game-feel issues as new slices in TRACKING.json

## Phase 1.5 — Two-Device Match + Backgrounding

- [ ] 2 real Android devices on WiFi/LTE
- [ ] Full match with ≥1 deliberate background per device
- [ ] Zero permanent desyncs, zero crashes

## Phase 2.4 — Full Rumble Start-to-Finish

- [ ] 2+ Android devices: lobby → match → rep award
- [ ] Zero developer console intervention

## Phase 3.4 — Sustained 60fps (Pixel 6a)

- [ ] Full rumble at target player count on Pixel 6a hardware
- [ ] 95th percentile frame time < 16.6ms for entire match

## Phase 4.3 — Adversarial Pass

Run `backend/auth_test_plan.md` matrix cold (next day, break-it mindset):

- [ ] Read another user's private data — must fail
- [ ] Forge match win — must fail
- [ ] Grant rep directly — must fail
- [ ] Bypass reconnect to duplicate rewards — must fail

## Phase 6.2 — Closed Testing Track

- [ ] Closed track on Play Console with external testers
- [ ] ≥5 non-developers install and complete a full match

## Phase 6.3 — Stability Bar (ongoing)

- [ ] Crash-free sessions ≥ 99%
- [ ] Zero open P0 bugs (crashes, data loss, unplayable states)
