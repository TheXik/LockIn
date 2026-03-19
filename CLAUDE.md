# LockIn — iOS Accountability App

## What this is
iOS app where friends hold each other accountable by locking distracting apps. Form "pacts" (2-4 people), lock apps via Apple Screen Time APIs, only pact members can approve unlocks. Think BeReal meets Screen Time.

## Current state
Full rebuild completed (March 17, 2026) — black/yellow redesign, accountability pact system, all core views and services wired up. Uncommitted.

## Tech stack
- **Language:** Swift 5.9, SwiftUI, iOS 16.0+
- **Backend:** Supabase (Postgres + RLS + Realtime)
- **Auth:** Sign in with Apple -> Supabase Auth
- **Screen Time:** FamilyControls, ManagedSettings, DeviceActivity
- **Push:** APNs via Supabase Edge Functions (Deno)
- **Project gen:** XcodeGen (`project.yml`)
- **SDK:** Supabase Swift SDK 2.0+

## Architecture

### App entry
`LockInApp.swift` — 5 `@StateObject` services injected via `.environmentObject()`. Flow: `SplashView` -> `AuthView` -> `MainTabView`.

### Tabs
0. Home — greeting, timer ring, pending requests, pacts list
1. Pacts — list/create/join
2. Lock — FamilyActivityPicker, schedule, daily limit, activate shield
3. Requests — approve/deny unlock requests
4. Settings — display name, sign out

### Services (all `@MainActor`, `ObservableObject`)
| Service | Role |
|---------|------|
| `AuthService` | Apple Sign In -> Supabase, profile CRUD |
| `PactService` | CRUD pacts + members (parallel TaskGroup) |
| `UnlockRequestService` | Send/approve/deny requests, Realtime v2 |
| `ScreenTimeAuthService` | FamilyControls authorization |
| `ShieldManager` | ManagedSettingsStore, state via App Group UserDefaults |
| `PushNotificationService` | APNs registration, token sync |
| `StreakService` | Streak computation from lock_sessions |

### Extensions
| Target | Bundle ID | Purpose |
|--------|-----------|---------|
| `ShieldConfigurationExtension` | `com.lockin.app.ShieldConfiguration` | Custom shield UI overlay |
| `ShieldActionExtension` | `com.lockin.app.ShieldAction` | "Request Unlock" from shield |
| `DeviceActivityMonitorExtension` | `com.lockin.app.DeviceActivityMonitor` | Screen time monitoring |

All share App Group `group.com.lockin.app` and `com.apple.developer.family-controls` entitlement.

### Design system
- **Colors:** OLED black bg, yellow `#FFD60A` primary, orange secondary (`Color+LockIn.swift`)
- **Components:** `LockInButton` (4 variants), `TimerRing`, `PactCard`, `RequestCard`, `AppIconGrid`
- **Modifiers:** `.lockInCard()`, `.lockInScreenBackground()`, `.loadingOverlay()`, `.errorBanner()`
- **Button style:** `ScaleButtonStyle` (0.97 scale on press)

## Constraints
- Supabase creds are placeholder in `Shared/Constants.swift` — need real project
- FamilyControls entitlement requires Apple Developer enrollment
- Must test on physical device (Screen Time APIs don't work in simulator)
- Push requires APNs Key (.p8), Team ID, Key ID in Supabase Edge Function secrets

## Build & run
```bash
xcodegen generate        # if project.yml changed
open LockIn.xcodeproj    # Cmd+B build, Cmd+R run (physical device)
```

## Notes
- Tab switching via NotificationCenter (`switchToRequestsTab`, `switchToPactsTab`)
- Invite codes: 6 chars, no ambiguous chars (0/O/1/I/L excluded)
- `supabase` is a global lazy `let` — falls back to localhost if creds not set
- All services use `@MainActor`
- `onChange(of:)` uses iOS 16 API (single param) — needs update for iOS 17+

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **LockIn** (613 symbols, 836 relationships, 1 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## When Debugging

1. `gitnexus_query({query: "<error or symptom>"})` — find execution flows related to the issue
2. `gitnexus_context({name: "<suspect function>"})` — see all callers, callees, and process participation
3. `READ gitnexus://repo/LockIn/process/{processName}` — trace the full execution flow step by step
4. For regressions: `gitnexus_detect_changes({scope: "compare", base_ref: "main"})` — see what your branch changed

## When Refactoring

- **Renaming**: MUST use `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` first. Review the preview — graph edits are safe, text_search edits need manual review. Then run with `dry_run: false`.
- **Extracting/Splitting**: MUST run `gitnexus_context({name: "target"})` to see all incoming/outgoing refs, then `gitnexus_impact({target: "target", direction: "upstream"})` to find all external callers before moving code.
- After any refactor: run `gitnexus_detect_changes({scope: "all"})` to verify only expected files changed.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Tools Quick Reference

| Tool | When to use | Command |
|------|-------------|---------|
| `query` | Find code by concept | `gitnexus_query({query: "auth validation"})` |
| `context` | 360-degree view of one symbol | `gitnexus_context({name: "validateUser"})` |
| `impact` | Blast radius before editing | `gitnexus_impact({target: "X", direction: "upstream"})` |
| `detect_changes` | Pre-commit scope check | `gitnexus_detect_changes({scope: "staged"})` |
| `rename` | Safe multi-file rename | `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` |
| `cypher` | Custom graph queries | `gitnexus_cypher({query: "MATCH ..."})` |

## Impact Risk Levels

| Depth | Meaning | Action |
|-------|---------|--------|
| d=1 | WILL BREAK — direct callers/importers | MUST update these |
| d=2 | LIKELY AFFECTED — indirect deps | Should test |
| d=3 | MAY NEED TESTING — transitive | Test if critical path |

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/LockIn/context` | Codebase overview, check index freshness |
| `gitnexus://repo/LockIn/clusters` | All functional areas |
| `gitnexus://repo/LockIn/processes` | All execution flows |
| `gitnexus://repo/LockIn/process/{name}` | Step-by-step execution trace |

## Self-Check Before Finishing

Before completing any code modification task, verify:
1. `gitnexus_impact` was run for all modified symbols
2. No HIGH/CRITICAL risk warnings were ignored
3. `gitnexus_detect_changes()` confirms changes match expected scope
4. All d=1 (WILL BREAK) dependents were updated

## Keeping the Index Fresh

After committing code changes, the GitNexus index becomes stale. Re-run analyze to update it:

```bash
npx gitnexus analyze
```

If the index previously included embeddings, preserve them by adding `--embeddings`:

```bash
npx gitnexus analyze --embeddings
```

To check whether embeddings exist, inspect `.gitnexus/meta.json` — the `stats.embeddings` field shows the count (0 means no embeddings). **Running analyze without `--embeddings` will delete any previously generated embeddings.**

> Claude Code users: A PostToolUse hook handles this automatically after `git commit` and `git merge`.

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
