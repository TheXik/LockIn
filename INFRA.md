# LockIn — Infrastructure Reference

## Xcode Project (`project.yml` — XcodeGen)

### Targets
| Target | Type | Bundle ID | Depends on |
|--------|------|-----------|------------|
| `LockIn` | application | `com.lockin.app` | ShieldConfig, ShieldAction, DeviceActivityMonitor, Supabase SDK |
| `ShieldConfigurationExtension` | app-extension | `com.lockin.app.ShieldConfiguration` | — |
| `ShieldActionExtension` | app-extension | `com.lockin.app.ShieldAction` | — |
| `DeviceActivityMonitorExtension` | app-extension | `com.lockin.app.DeviceActivityMonitor` | — |

### Shared config
- Deployment target: iOS 16.0
- Swift 5.9, iPhone only
- App Group: `group.com.lockin.app` (all 4 targets)
- Entitlement: `com.apple.developer.family-controls` (all 4 targets)
- `DEVELOPMENT_TEAM`: empty — must set before building

### Source layout
- Main app sources: `LockIn/` + `Shared/`
- Each extension sources: `<ExtensionDir>/` + `Shared/`
- `Shared/Constants.swift` is compiled into all 4 targets

## Supabase Backend

### Credentials
Set in `Shared/Constants.swift` — currently placeholder values:
```swift
static let supabaseURL = "YOUR_SUPABASE_URL"
static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
```
The `supabase` global (in `SupabaseClient.swift`) falls back to `localhost:54321` if these aren't configured.

### Database schema (`supabase/migrations/`)

**001_initial_schema.sql:**
| Table | Key columns | RLS |
|-------|-------------|-----|
| `profiles` | id (FK auth.users), display_name, avatar_emoji, push_token | select: any, insert/update: own |
| `pacts` | id, name, invite_code (unique), created_by | select: members + any authed, insert: own |
| `pact_members` | pact_id, user_id (unique pair), max 4 per pact | select: co-members, insert: own, delete: own |
| `lock_sessions` | user_id, pact_id, app_identifiers[], schedule_start/end, schedule_days[], daily_limit_minutes, is_active | select: co-members, insert/update: own |
| `unlock_requests` | requester_id, pact_id, lock_session_id (nullable), app_identifier, reason, status (pending/approved/denied), responder_id | select: co-members, insert: own, update: co-members (not self) |

Realtime enabled on: `unlock_requests`, `pact_members`

**002_push_notifications.sql:**
- Index on `profiles.push_token` (where not null)
- Index on `lock_sessions(user_id, created_at desc)` for streak queries
- Index on `lock_sessions(pact_id, is_active)` where active
- Added `profiles.notifications_enabled` boolean (default true)

### Edge Functions (`supabase/functions/`)

Both functions use the same APNs JWT pattern (ES256, jose library).

**`push-notification/index.ts`** — triggered by DB webhook on `unlock_requests` INSERT:
1. Gets requester's display name
2. Finds all other pact members' push tokens
3. Sends APNs alert to each: "X wants to unlock an app"
4. Custom payload includes `type: "unlock_request"`, `pact_id`, `requester_id` for deep linking

**`request-response/index.ts`** — triggered by DB webhook on `unlock_requests` UPDATE:
1. Only fires when status changes from `pending` to `approved`/`denied`
2. Gets responder's name
3. Sends APNs alert to requester: "X approved/denied your request"
4. Custom payload includes `type: "request_approved"` or `"request_denied"`

### Required Supabase secrets
```
SUPABASE_URL              # auto-set
SUPABASE_SERVICE_ROLE_KEY  # auto-set
APNS_KEY_ID               # Apple Developer -> Keys
APNS_TEAM_ID              # Apple Developer -> Membership
APNS_BUNDLE_ID            # com.lockin.app (default)
APNS_KEY_P8               # .p8 file contents
APNS_ENV                  # "development" or "production"
```

### Required DB webhooks (configured in Supabase Dashboard)
1. `push-notification-on-unlock-request` — table: `unlock_requests`, event: INSERT -> `/functions/v1/push-notification`
2. `push-notification-on-request-response` — table: `unlock_requests`, event: UPDATE -> `/functions/v1/request-response`

Both need header: `Authorization: Bearer <service_role_key>`

## Apple Developer Requirements

### Entitlements needed
- **FamilyControls** — requires explicit capability request from Apple (can take 1-2 weeks)
- **Push Notifications** — standard capability
- **App Groups** — `group.com.lockin.app`
- **Sign in with Apple** — standard capability

### APNs setup
1. Create a Key in Apple Developer -> Keys -> APNs
2. Download the `.p8` file (one-time download)
3. Note the Key ID and Team ID
4. Add all as Supabase Edge Function secrets

## App Group shared data
The App Group `group.com.lockin.app` is used by `ShieldManager` to persist lock state via `UserDefaults(suiteName:)`, shared between the main app and all 3 extensions. This allows extensions to read the current lock configuration without querying Supabase.
