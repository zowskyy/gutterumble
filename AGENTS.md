# Agent instructions — GutterRumble

Godot 4.7 Android-first multiplayer street-brawler.

## Principles

- Inspect before modifying; source code beats stale docs.
- Reuse existing systems; do not reimplement what already works.
- Do not leave TODO/FIXME stubs for core features.
- Never put Supabase service-role credentials in the Android client.
- Authoritative combat runs on a dedicated Godot match server; clients send inputs only.
- Supabase is for auth, persistence, matchmaking metadata, profiles, progression, and results.
- Preserve offline single-player.

## Environment

Optional cloud bootstrap: `bash scripts/install-agent-environment.sh`
