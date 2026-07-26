# LockIn — App Store Connect metadata (copy-paste ready)

App: **LockIn: Focus Together** · Apple ID `6761286908` · bundle `com.lukashellesch.lockin`
Team `Y2JC2VK9VP` (Individual — Lukáš Hellesch). Free, no IAP.
Every field below is within Apple's character limit (verified).

---

## App Information

| Field | Value | Chars |
|---|---|---|
| Name | `LockIn: Focus Together` | 22/30 |
| Subtitle | `Your friends hold the key` | 25/30 |
| Category | **Productivity** (primary), secondary empty | — |
| Content Rights | does NOT contain third-party content | — |

## Pricing
Free · all countries and regions.

---

## Version 1.0 page

### Promotional Text (170 max — editable anytime without review)
```
Willpower is a liar at 1am. LockIn hands your unlock key to 2-4 friends who decide when you get the app back. Real Screen Time blocking, not another timer you can skip.
```
168/170

### Description (4000 max)
```
Willpower is a liar. It's loudest right after you've failed, and quietest at 1am when you're three reels deep.

LockIn is the accountability app where your friends hold the key.

Pick the apps that own you — TikTok, Instagram, X, whatever you keep opening without deciding to. Lock them behind Apple's Screen Time. Then hand the key to 2-4 friends.

When you want an app back before your timer is up, you don't get to decide. You send an unlock request, with your excuse attached, and it lands on your friends' phones. They approve. Or they deny.

That pause — where you have to explain yourself to someone who knows you — is the whole product.

HOW IT WORKS
1. Pick your poison. Choose the apps that eat your day.
2. Make the pact. Send a code to 1-3 friends. You can't lock in alone.
3. Ask permission. Want an app back early? Send a request.
4. Live with the verdict. They approve, or they deny.

WHY IT WORKS WHEN NOTHING ELSE DOES
- Real blocking, not a VPN trick. LockIn uses Apple's Screen Time (FamilyControls) — there's no toggle buried in Settings that hands the app back.
- Your people, not a robot. Not a coach, not a subscription that emails you a chart. The friends who'll bring it up at dinner.
- Small groups. 2-4 people. Big enough that someone's awake, small enough that it's personal.
- Free to lock in. Pick apps, make a pact, send requests, hold each other to it.

PRIVACY
Your Screen Time data never leaves your device. LockIn stores only your account, your pact membership, and your unlock requests. We never see which apps you use or for how long. No ads, no trackers, no data brokers.

Requires iOS 16 and at least one friend who will actually tell you no.
```

### Keywords (100 max, no spaces after commas)
```
screen time,app blocker,block apps,distraction,accountability,self control,study,detox,discipline
```
97/100. Deliberately avoids words already in the Name/Subtitle (focus, together, friends, key) — Apple indexes those separately.

### URLs
- Support URL: `https://locked-in.dev`
- Marketing URL: `https://locked-in.dev`
- Privacy Policy URL: `https://locked-in.dev/privacy` (verified live, HTTP 200)
- Copyright: `2026 Lukas Hellesch`

---

## Screenshots
Five, at **1320 × 2868 (6.9")**, in `LockIn/docs/appstore-screenshots/`. Upload this one size only — Apple auto-scales down. No alpha channel (verified).

| # | File | Caption |
|---|---|---|
| 1 | `01_pick.png` | Pick the apps **that own you.** |
| 2 | `02_pact.png` | Hand the key to **2–4 friends.** |
| 3 | `03_verdict.png` | They decide when **you get back in.** |
| 4 | `04_locked.png` | Real blocking. **No off switch.** |
| 5 | `05_streak.png` | Build the streak **together.** |

---

## App Privacy (nutrition labels)

Collect data: **YES**. Tracking: **NO** (→ no ATT prompt).

All of these: **Linked to the user**, purpose **App Functionality**, **not** used for tracking.

| Data | Category |
|---|---|
| Email address (Sign in with Apple) | Contact Info → Email Address |
| Display name | Contact Info → Name |
| Account ID | Identifiers → User ID |
| **Push token** | Identifiers → **Device ID** ⚠️ **Linked** — a token on a user row IS the linkage. Declaring it Not-Linked is a false label and a 5.1.1 exposure. |
| Pact membership, unlock requests | Usage Data → Product Interaction |

**Do NOT declare** Screen Time / FamilyActivitySelection — it never leaves the device, so it isn't "collected" under Apple's definition. That on-device boundary is also the defence for the FamilyControls entitlement.

---

## App Review Information

Sign-in required: **YES** (Sign in with Apple).

```
LockIn is a personal focus app built on Apple's FamilyControls (Screen Time) framework. Each user authorizes Family Controls for their own device using .individual authorization and selects their own apps to restrict. A pact member can only approve or decline an unlock request that the user initiated, for restrictions the user chose for themselves. Nobody can manage another person's device, select their apps, or see their usage data.

Screen Time / FamilyActivitySelection data never leaves the device. Our backend stores only account records, pact membership, and unlock request events.

HOW TO TEST
1. Sign in with Apple.
2. Pacts tab - Create a pact. You receive a 6-character invite code.
3. Lock tab - grant Screen Time permission, choose apps, tap Lock In.
4. The approve/deny flow needs a second account joining with the invite code. If a second device isn't available, note that any lock can be removed at Settings - Danger Zone - Remove All Locks, so the device can never get stuck.

ACCOUNT DELETION: Settings - Danger Zone - Delete Account (type DELETE to confirm). This permanently deletes the account and all associated data.
```

> ⚠️ **Known review risk:** the core approve/deny loop needs two people, and RLS forbids approving your own request (`auth.uid() != requester_id`). A lone reviewer cannot exercise it. Mitigate by creating a second test account and giving the reviewer its invite code in the notes — or by adding them to TestFlight. The "Remove All Locks" escape hatch is documented above so they can never get stuck.

---

## Still to do (only Lukáš can)
- [ ] Digital Services Act trader information (legal declaration; publishes name + address for EU)
- [ ] Archive a Release build in Xcode → upload to App Store Connect
- [ ] Attach the build to version 1.0
- [ ] Submit for Review

Already done: Individual enrollment (Team `Y2JC2VK9VP`), FamilyControls **Distribution entitlement Assigned**, age rating, category, `ITSAppUsesNonExemptEncryption = false` (in `LockIn/Info.plist`), account deletion (deployed to Supabase), `device_tokens` table (deployed).
