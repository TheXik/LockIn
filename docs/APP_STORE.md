# LockIn — App Store Submission Package

## App Store Metadata

**App Name:** LockIn — Focus with Friends
**Subtitle:** Your friend has the key
**Category:** Health & Fitness (primary) / Productivity (secondary)
**Price:** Free
**Age Rating:** 4+

---

## Description

Your friend has the key. Literally.

LockIn is the only app where your real friends hold you accountable. Pick the apps that kill your focus — TikTok, Instagram, Twitter, whatever — and lock them down. The catch? Only your squad can approve an unlock.

**How it works:**
1. Pick apps to block (uses Apple Screen Time — no VPN tricks, real OS-level blocking)
2. Form a pact with 1-3 friends
3. When you need an app back, send an unlock request
4. Your friend decides if it's worth it

**Why LockIn is different:**
• Group accountability — 2-4 people in a pact, not just 1-to-1
• Real blocking — uses Apple's FamilyControls, not a VPN workaround
• Social pressure that works — your streak is visible to your squad
• No subscription needed — core features are free forever

**Built for:**
• Founders who can't stop checking Twitter
• Students who lose hours to TikTok before exams
• Anyone who's tried Screen Time limits and just... tapped "Ignore"

The difference between Screen Time and LockIn? You can't override your friend.

---

## Keywords (100 char max)

screen time,focus,block apps,accountability,digital wellbeing,app blocker,focus timer,productivity

---

## Promotional Text (170 char max — can be updated without review)

Lock your distracting apps. Your friend approves the unlock. Build streaks together. The accountability app that actually works.

---

## What's New (first version)

Welcome to LockIn! 🔥

• Lock any app using Apple Screen Time — real OS-level blocking
• Form pacts with 1-3 friends for accountability
• Unlock requests — your squad decides if you really need that app
• Streak tracking — see how many days you've stayed focused
• Push notifications when your squad needs you

---

## App Review Notes

LockIn uses the FamilyControls framework to allow users to voluntarily block distracting apps on their own device. This is a self-directed accountability tool — users choose which apps to block and form voluntary groups ("pacts") with friends who can approve unlock requests.

Key technical details:
- Uses AuthorizationCenter.shared.requestAuthorization(for: .individual) — this is for the user's OWN device, not parental controls
- ManagedSettingsStore applies/removes shields based on user's own selections
- ShieldConfigurationExtension provides a custom branded overlay when a blocked app is opened
- ShieldActionExtension allows users to send an unlock request directly from the shield overlay
- All data synced via Supabase with row-level security

Test account: [will be created before submission]
Test pact invite code: [will be provided]

To fully test: Create two accounts, form a pact, lock apps on one device, then approve/deny unlock from the other.

---

## FamilyControls Entitlement Request

**App Name:** LockIn
**Bundle ID:** com.lockin.app
**Team ID:** [fill after activation]

**Description of use:**

LockIn is a social accountability app that uses FamilyControls to help users voluntarily block distracting apps on their own device. Users form small groups ("pacts") of 2-4 friends, and when someone wants to unlock a blocked app, their pact members must approve the request.

We use FamilyControls in the following way:
1. AuthorizationCenter.shared.requestAuthorization(for: .individual) — users authorize their own device
2. FamilyActivityPicker — users select which of their own apps to block
3. ManagedSettingsStore — applies/removes app shields based on user's voluntary selections
4. ShieldConfigurationExtension — displays a branded overlay when a blocked app is opened
5. ShieldActionExtension — allows the user to request an unlock from the shield overlay
6. DeviceActivityMonitor — tracks usage against user-defined daily limits

This is NOT a parental control app. It is a peer accountability tool where all participants are adults who voluntarily opt in. No one can remotely lock another person's apps — each user controls their own device and chooses to participate.

The social accountability model (requiring friend approval for unlocks) is what makes this effective where Apple's built-in Screen Time limits fail — users can't simply override the restriction themselves.

---

## Privacy Nutrition Labels

**Data Linked to You:**
- Email Address (Sign in with Apple)
- Name (Display name, user-provided)

**Data Not Linked to You:**
- Device ID (push notification token)
- Usage Data (anonymous app blocking counts)

**Data NOT Collected:**
- Location
- Contacts
- Browsing History
- Photos
- Health & Fitness
- Financial Info
- Sensitive Info
- Search History

---

## Screenshots Needed

5 screenshots per device size. Required sizes:
- iPhone 6.7" (iPhone 15 Pro Max) — 1290 x 2796
- iPhone 6.1" (iPhone 15 Pro) — 1179 x 2556
- Optional: iPhone 5.5" (iPhone 8 Plus) — 1242 x 2208

**Screenshot plan:**
1. **Onboarding** — "Your friend has the key" with emoji orbs
2. **Home** — Focus ring active, streak badge, squad orbit
3. **Lock Setup** — App picker with selected apps, schedule options
4. **Unlock Request** — Notification from pact member asking to unlock
5. **Pact** — Pact card with members, invite code, activity
