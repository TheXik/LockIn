# LockIn — Product Strategy & Shipping Plan

## The Competitive Landscape (TL;DR)

**20+ apps** in the screen time space. The big ones:
- **Opal** ($10M ARR, $100/yr) — best analytics, weak blocking (VPN-based, easily bypassed)
- **one sec** (4.8★, 100K+ reviews) — breathing pause before apps, not hard blocking
- **Brick** ($59 NFC puck, 60K units) — physical friction, became a lifestyle/status object
- **Clearspace** (YC W23, $6M raised) — "do push-ups to unlock", memorable gimmick
- **Jomo** (4.8★, bootstrapped) — clean indie app, Apple-recommended

**The accountability niche specifically:**
- **Sheppie** — 1 shepherd approves your unlocks. 10K users, 4.8★. Users with a shepherd stick 8× longer (86 days vs 11 days solo). **Closest competitor.**
- **Poke** — friend codes, leaderboards, competition-focused. Early stage.
- **Friend Controls** — basic 1-friend approval. Solo dev.
- **FriendLock** — earn screen time by taking selfies with friends IRL. Novelty.

**Nobody has built group accountability pacts (2-4 people). That's the gap.**

## Why LockIn Can Win

### 1. Group pacts are the white space
Sheppie proved 1-to-1 accountability = 8× better retention. LockIn's bet: small group dynamics (2-4 people) are even more powerful due to social pressure, shared commitment, and FOMO.

### 2. Built-in viral loop
You literally can't use LockIn alone. Every user must invite 1-3 friends. This is structural K-factor > 1 growth, like early BeReal. No marketing spend needed for initial traction.

### 3. The approval moment is content gold
"My co-founder just denied my TikTok unlock request" — this is a TikTok video waiting to happen. The tension + humor + relatability of the approve/deny interaction creates organic content.

### 4. "Lock In" is already Gen Z slang
"Lock in" means "get serious / commit / focus up." The name does the marketing.

### 5. FamilyControls = real blocking
Unlike Opal/Freedom (VPN-based, trivially bypassed), LockIn uses Apple's FamilyControls — OS-level blocking that can't be toggled off from Settings.

## What Needs to Change

### Kill the generic, lean into the social
Current app feels like "another screen time settings panel." Every screen should reinforce that this is about YOUR PEOPLE holding you accountable, not a robot restricting you.

### Key pivots:
1. **Flame > Lock** — positive energy (building streaks) not punishment (being locked)
2. **Squad > Settings** — show your pact members everywhere, not just in a tab
3. **Drama > Data** — the approve/deny interaction should feel dramatic, urgent, fun
4. **Free > Expensive** — free core, premium for power features

## Feature Prioritization for App Store Launch

### Must Have (MVP — Ship This)
- [x] Sign in with Apple
- [x] Create/join pacts (invite codes)
- [x] Lock apps (FamilyActivityPicker + ManagedSettingsStore)
- [x] Unlock requests (send, approve, deny)
- [x] Realtime updates (Supabase Realtime)
- [x] Black/yellow design system
- [x] Home screen with focus ring + squad
- [ ] **Shield Configuration Extension** — custom branded overlay when a locked app is opened (not the generic iOS one)
- [ ] **Shield Action Extension** — "Request Unlock" button directly on the shield overlay
- [ ] **Persist lock state** — survive app restarts (UserDefaults + App Group)
- [ ] **Persist selected apps** — same, App Group shared with extensions
- [ ] **Streak tracking** — compute from lock_sessions, show prominently
- [ ] **Push notifications** — APNs for unlock requests (critical for UX — your friend needs to respond!)
- [ ] **Onboarding flow** — first launch: explain the concept, request Screen Time permission, create or join first pact
- [ ] **Error handling** — proper error states in all views, not just print()
- [ ] **App icon** — distinctive, black/yellow, flame motif
- [ ] **App Store assets** — screenshots, description, keywords

### Should Have (v1.1 — First Update)
- [ ] Squad member lock status (real-time: who's locked in right now)
- [ ] Pact activity feed (who locked/unlocked, who approved/denied)
- [ ] Streak leaderboard within pacts
- [ ] Share pact invite via iMessage / WhatsApp link
- [ ] Haptic feedback throughout
- [ ] Widget (lock status + streak)
- [ ] Profile customization (emoji picker, display name)

### Nice to Have (v1.2+)
- [ ] Analytics dashboard (daily/weekly screen time trends)
- [ ] Custom schedules per pact
- [ ] "Accountability score" — gamified metric
- [ ] Dark/light mode toggle (currently forced dark)
- [ ] iPad support
- [ ] Android version

## Pricing Strategy

**Free tier (core experience):**
- 1 pact (up to 4 members)
- Full locking + unlock request flow
- Basic streak tracking

**Premium ($2.99/mo or $19.99/yr):**
- Unlimited pacts
- Detailed analytics + insights
- Custom shield overlays
- Priority push notifications
- Export usage data

This undercuts Opal ($100/yr) and Clearspace ($37/yr) while making the core viral loop free.

## Go-to-Market

### Phase 1: Friends & Family (Week 1-2)
- Ship to TestFlight with 10-20 real users
- Get 3-5 real pacts running
- Fix bugs, polish UX based on real usage

### Phase 2: App Store Launch (Week 3)
- Submit to App Store (need Apple Developer + FamilyControls entitlement approval)
- Launch with press-worthy framing: "The screen time app that needs your friends"
- Post on Product Hunt, Hacker News, r/nosurf, r/productivity, r/digitalminimalism

### Phase 3: Content Engine (Week 4+)
- Create TikTok account, post "my friend denied my unlock" moments
- Encourage users to share their approve/deny interactions
- Partner with productivity/focus creators

### Phase 4: Iterate (Month 2+)
- Add features based on real user feedback
- Focus on retention metrics: DAU, streak length, pact survival rate
- Consider YC application (this is exactly the kind of app they fund)

## Technical Gaps to Close

### Critical for App Store submission:
1. **Real Supabase project** — replace placeholder credentials
2. **FamilyControls entitlement** — requires Apple Developer enrollment + capability request (can take 1-2 weeks)
3. **Privacy policy + terms** — required for App Store
4. **Shield extensions** — must be functional, not stubs
5. **App Group container** — shared data between main app and extensions
6. **Crash-free startup** — handle all nil states, missing data, network errors

### Nice before launch but not blocking:
- Push notification infrastructure (Supabase Edge Functions + APNs)
- Analytics (basic Supabase queries suffice initially)
- Deep linking for invite codes (can use simple paste for MVP)
