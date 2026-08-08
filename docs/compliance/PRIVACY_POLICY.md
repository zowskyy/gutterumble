# Privacy Policy — GUTTERUMBLE

**Effective date:** [INSERT DATE]  
**Contact:** privacy@gutterumble.dev  
**Operator:** [INSERT LEGAL ENTITY NAME]

> Template for Play Store listing. Replace bracketed placeholders before publishing.

---

## Overview

GUTTERUMBLE ("the Game") is a mobile fighting game. This policy explains what data we collect, why, and your choices. By playing the Game you agree to this policy.

---

## Data we collect

### Account information (Supabase Auth)

When you create an account we collect:

- **Email address** — used for sign-in, password reset, and account recovery.
- **User ID** — an opaque UUID that links your profile, characters, and match history.

We do not collect your real name unless you voluntarily set a display name.

### Gameplay data

To provide multiplayer, progression, and customization we store:

- Character names, appearance choices, reputation (rep), and level.
- Match results (placement, stats, rep earned).
- Lobby participation and cosmetic inventory unlocks.

This data is stored in our Supabase database and is scoped to your account via row-level security.

### Device diagnostics

The Game may write crash reports and performance logs to your device's local storage (`user://crashes/`, `user://perf_log.csv`). These files stay on your device unless you choose to share them with support. Release builds may disable performance logging.

We do **not** collect precise location, contacts, photos, or payment card numbers directly. If in-app purchases are added, transaction verification is handled by Google Play — we receive only purchase tokens, not card details.

---

## How we use data

| Purpose | Legal basis |
|---------|-------------|
| Account creation and authentication | Contract (providing the Game) |
| Matchmaking and multiplayer | Contract |
| Progression, leaderboards, unlocks | Contract |
| Crash debugging and stability | Legitimate interest |
| Abuse prevention (rate limits, RLS) | Legitimate interest |

We do not sell your personal data. We do not use your data for third-party advertising.

---

## Third-party services

| Service | Role | Data shared |
|---------|------|-------------|
| [Supabase](https://supabase.com/privacy) | Authentication, database, hosting | Email, user ID, gameplay records |
| Google Play | App distribution, optional IAP | Device info per Google's policy |

---

## Data retention

- Account data is kept while your account is active.
- Match history is retained for leaderboard and progression purposes.
- You may request deletion of your account and associated data by emailing **privacy@gutterumble.dev**. We will delete within 30 days except where law requires retention.

---

## Security

- All network traffic uses TLS (HTTPS).
- Database access is protected by Row Level Security — your session can only read and write your own rows.
- Privileged actions (rep awards, inventory grants) run server-side with service credentials never embedded in the app.

---

## Children's privacy

The Game is not directed at children under 13. We do not knowingly collect data from children under 13. Contact us to request deletion if you believe a child provided personal information.

---

## Your rights

Depending on your region you may have rights to access, correct, delete, or export your data. Email **privacy@gutterumble.dev** with your account email to exercise these rights.

---

## Changes

We may update this policy. Material changes will be announced in-app or on our store listing. Continued use after changes constitutes acceptance.

---

## Contact

**privacy@gutterumble.dev**
