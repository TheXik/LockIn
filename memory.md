# LockIn — Session Memory

## Timeline
- **2026-03-17** — Initial scaffold created
- **2026-03-17** — Full rebuild: accountability pact system + black/yellow redesign (commit `39aa55f`)
- **2026-03-17** — 23 files modified + 3 new (uncommitted) — active UI/service refinements
- **2026-03-17** — Major UI redesign: social-first home, flame focus ring, new auth screen, emoji avatars

## What's been built
- [x] Project scaffold (XcodeGen, extensions, app group)
- [x] Auth flow (Sign in with Apple → Supabase)
- [x] Supabase schema (profiles, pacts, pact_members, lock_sessions, unlock_requests) with RLS
- [x] Pact system (create with invite code, join, leave, member list)
- [x] Lock setup (FamilyActivityPicker, schedule options, daily limit slider)
- [x] Shield activation/deactivation (ManagedSettingsStore)
- [x] Unlock request flow (send request, approve/deny, Realtime listener)
- [x] Full UI: Home, Pacts, Lock, Requests, Settings tabs
- [x] Design system: black/yellow theme, LockInButton, TimerRing, PactCard, RequestCard
- [x] View modifiers: lockInCard, lockInScreenBackground, loadingOverlay, errorBanner
- [x] Splash screen + auth screen with spring animations
- [x] **REDESIGN: TimerRing → FocusRing with flame icon + squad orbit bubbles**
- [x] **REDESIGN: HomeView — greeting + streak badge, focus ring, stats row, social CTA**
- [x] **REDESIGN: AuthView — "Your friend has the key" + rotating taglines + social emoji pair visual**
- [x] **REDESIGN: PactCard — emoji avatars, empty slot indicators, bold invite code**
- [x] **REDESIGN: Settings — emoji avatar instead of initial**
- [x] Added `switchToLockTab` notification + handler in ContentView
- [x] **NEW: Splash screen** — phased animation (flame → text → glow → loading dots), not just a static spinner
- [x] **NEW: Lock celebration overlay** — full-screen flame animation when you hit "Lock In"
- [x] **REDESIGN: LockSetupView** — "How it works" onboarding card, better schedule picker with icons/subtitles, empty state for app selection, improved layout
- [x] **Canva logo generation** — 4 candidates generated, user picking
- [x] **Strategy doc** — full competitive research + shipping plan at docs/STRATEGY.md

## What's been built (continued — March 18)
- [x] **Push Notification Service** — PushNotificationService.swift: permission request, APNs token registration, token saved to Supabase `profiles.push_token`, notification handling with deep linking
- [x] **AppDelegate** — wired UIApplicationDelegateAdaptor for push notification callbacks, foreground banner display
- [x] **Supabase Edge Functions** — `push-notification/index.ts` (fires on unlock_request INSERT, sends APNs to all pact members except requester) + `request-response/index.ts` (fires on UPDATE, notifies requester of approve/deny)
- [x] **DB Migration 002** — push_token index, notifications_enabled column, lock_sessions indexes for streak computation
- [x] **Onboarding Flow** — 4-page swipe flow: welcome → how it works → Screen Time permission → push notification permission. Page indicators, skip buttons, animated orbs
- [x] **Persist Lock State** — ShieldManager now uses App Group UserDefaults. Lock state, selected apps, and lock start time survive app restarts. Auto-reapplies shields on launch
- [x] **Lock Duration Tracking** — `lockStartedAt` timestamp, `lockDurationFormatted` computed property shown in HomeView and LockSetupView
- [x] **Streak Service** — StreakService.swift: computes currentStreak, longestStreak, totalLockDays, totalLocksThisWeek from Supabase lock_sessions. Consecutive day logic with today/yesterday grace
- [x] **HomeView uses real streak** — removed hardcoded `streakDays = 0`, now reads from StreakService
- [x] **Settings: streak stats** — shows current/longest streak + total lock days in a nice stats card
- [x] **Settings: notification toggle** — shows push permission status with enable button
- [x] **Settings: legal section** — Privacy Policy and Terms of Service links with full in-app views
- [x] **Privacy Policy view** — what we collect/don't collect, Screen Time explanation, data storage/deletion, third parties
- [x] **Terms of Service view** — responsibilities, limitations, plain language
- [x] **Error handling** — added errorBanner to CreatePactView, JoinPactView, LockSetupView (already existed on RequestsView)
- [x] **Active lock banner improved** — shows lock duration + app count

## What's next (not started)
- [ ] Commit all new work
- [ ] Set up real Supabase project and replace placeholder creds
- [ ] Implement squad member lock status (query lock_sessions.is_active for each member)
- [ ] Shield configuration extension (custom overlay when blocked app is opened)
- [ ] Shield action extension (trigger unlock request from shield overlay)
- [ ] DeviceActivity monitor extension (track daily usage against limits)
- [ ] Profile editing (emoji avatar picker)
- [ ] Pact detail improvements (show member lock status, activity feed)
- [ ] Polish: haptics throughout, better transitions
- [ ] App Store assets (screenshots, description, keywords)

## Known issues / tech debt
- `Constants.swift` has placeholder Supabase URL/key — app will fall back to localhost
- `onChange(of:)` uses deprecated iOS 16 single-param syntax (TimerRing.swift)
- `PrivacyInfo.xcprivacy` is new/untracked — needs to be committed
- Realtime channel listens to ALL unlock_requests inserts, not filtered by pact — may over-fetch
- Squad member `isLockedIn` is hardcoded to `false` — needs lock_sessions query
- Timer in AuthView for rotating taglines could leak — should use `.onReceive` with Timer.publish
- APNs edge functions need real Apple Push Key (.p8) and Team ID configured in Supabase secrets
- Shield extensions are stubs — need real custom UI for blocked app overlay

## Design decisions
- **Black/yellow palette** — BeReal × Duolingo vibe, OLED-friendly, stands out from typical blue/purple apps
- **Max 4 members per pact** — keeps groups intimate and accountable
- **Invite codes** — 6 uppercase chars, no ambiguous characters (O/0/I/1/L excluded)
- **Always dark mode** — `.preferredColorScheme(.dark)` forced at app level
- **Flame metaphor** — 🔥 as the core visual (not lock/shield). Represents energy, streaks, positive focus
- **Squad orbit on TimerRing** — pact members orbit the focus ring, reinforcing social accountability
- **Emoji avatars** — more personality than initials, assigned randomly on signup
- **"Your friend has the key"** — core tagline that communicates the unique value prop in 6 words
- **Stats row** — gamification (blocked apps, streak days, resisted unlocks) makes it sticky
- **No-pacts CTA** — shows two connected emojis (🔥←→💪) to communicate the social concept visually
- **Global Supabase client** — lazy `let` with graceful localhost fallback
- **NotificationCenter for tab switching** — simple cross-view communication without tight coupling
