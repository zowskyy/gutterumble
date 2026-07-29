# Audio Assets

Drop files here. AudioManager will pick them up automatically — no code changes needed.
`AudioManager.gd`'s `SFX_PATHS`/`MUSIC_PATHS`/`BARK_PATHS` dictionaries are the source of
truth for exact filenames/extensions — this table should match them.

## sfx/ — Sound effects

| Filename | When it plays | Status |
|---|---|---|
| `hit_light.wav` | Light attack lands | ✅ wired (mixkit) |
| `hit_heavy.wav` | Heavy attack lands | ✅ wired (mixkit) |
| `hit_ko.mp3` | KO blow | ✅ wired (ElevenLabs) |
| `dodge.mp3` | Dodge roll starts | ✅ wired (ElevenLabs) |
| `ui_confirm.mp3` | Button press | ✅ wired (ElevenLabs) |
| `ui_back.mp3` | Back / cancel | ⚠️ not generated — currently reuses `ui_confirm.mp3` in code, add a distinct file at this path to override |
| `countdown.mp3` | Round countdown tick | ✅ wired (ElevenLabs) |
| `fight_start.mp3` | "FIGHT!" moment | ✅ wired (ElevenLabs) |
| `win.mp3` | Player wins a round | ✅ wired (ElevenLabs) |
| `lose.mp3` | Player loses a round | ✅ wired (ElevenLabs) |
| `combo_milestone.ogg` | "Gutter Streak" crosses a tier (6, 10, or 15 hits) — a short rising stinger works well | ❌ not generated yet |
| `special_activate.mp3` | Player unleashes the special AOE at full gauge | ✅ wired (ElevenLabs) |

## sfx/barks/ — Crowd chatter

| Filename | When it plays | Status |
|---|---|---|
| `bark_01.mp3`–`bark_05.mp3` | Random taunt/grunt from an enemy approaching or idling in Warriors mode (not one mid-attack/dodge/hit-react) — picked randomly, one at a time, at most every 4 seconds regardless of wave size | ✅ wired (ElevenLabs male/female taunter lines) |

## music/ — Music loops

| Filename | When it plays | Status |
|---|---|---|
| `arena_theme.mp3` | In-arena background music | ✅ wired — **note:** MP3 has inherent encoder padding at the start, so the loop point (`AudioStreamMP3.loop = true`, set in code) may have an audible seam. Convert to OGG Vorbis for sample-accurate looping if the seam is noticeable. |
| `menu_theme.mp3` | Main menu background | ✅ wired — same MP3-loop-seam caveat as above |

## Unused inventory available in `C:\Users\mrscp\Desktop\gutterumble music\`

Not currently wired to any AudioManager slot, but generated/collected and sitting there —
useful for future expansion (extra hit-reaction voice grunts, a creature roar, more taunt
variety, alternate hit sounds):

- `end_match_taunt_loser.mp3` — could work well as a dedicated post-match loss line
- Remaining `ElevenLabs_*Brawler Announcer*` and `*TAUNTER*` clips beyond the 5 used for barks
- `mixkit-battle-man-scream-2175.wav`, `mixkit-body-cutting-impact-2199.wav`,
  `mixkit-boxer-getting-hit-2055.wav`, `mixkit-effort-man-voice-2170.wav`,
  `mixkit-female-exclamation-of-pain-2206.wav`, `mixkit-fighting-mans-voice-2171.wav`,
  `mixkit-fighting-man-voice-2172.wav`, `mixkit-fighting-man-voice-of-pain-2173.wav`,
  `mixkit-impact-of-a-strong-punch-2155.mp3`, `mixkit-knife-fast-hit-2184.wav`,
  `mixkit-kung-fu-strike-with-effort-2162.wav`, `mixkit-martial-arts-kick-2163.wav`,
  `mixkit-nasty-criature-roar-2781.wav`, `mixkit-punch-through-air-2141.mp3`,
  `mixkit-quick-knife-slice-cutting-2152.mp3`, `mixkit-scream-in-pain-2200.wav`,
  `mixkit-sword-cutting-flesh-2788.wav`, `mixkit-voice-from-effort-to-punch-2174.wav`,
  `mixkit-woman-cry-of-pain-2201.wav`
- `Forceful_punch_impac_*` variants (alternate hit_light/hit_heavy candidates)
- `very_visceral,_gritt_*` and `Visceral_bone-crunch_*` (alternate hit_heavy/hit_ko candidates)
- `Deep_resonant_hum_wi_*` (unclear intended use — ambient drone?)

## Free sources (license-friendly, if more variety is needed)
- https://freesound.org (CC0 / CC-BY — check per file, add to CREDITS if CC-BY)
- https://opengameart.org (filter by CC0)
- https://pixabay.com/sound-effects (free for commercial use)
- Mixkit (https://mixkit.co) — free license, no attribution required, logged in CREDITS.md regardless per project convention
- ElevenLabs Sound Effects — AI-generated, licensed per your ElevenLabs plan
