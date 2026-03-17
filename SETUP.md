# LockIn — Setup Guide

## 1. Supabase Setup

### Create Project
1. Go to [supabase.com](https://supabase.com) → New Project
2. Name it `lockin`, choose a region close to you, set a database password
3. Wait for it to provision (~2 minutes)

### Run Database Migration
1. Go to **SQL Editor** in the Supabase dashboard
2. Paste the contents of `supabase/migrations/001_initial_schema.sql`
3. Click **Run** — this creates all tables with Row Level Security

### Configure Auth (Sign in with Apple)
1. Go to **Authentication → Providers → Apple**
2. Toggle it on
3. In **Client IDs**, enter: `com.lockin.app`
4. Leave other fields blank
5. Save

### Get Your Keys
1. Go to **Settings → API**
2. Copy the **Project URL** (e.g. `https://abc123.supabase.co`)
3. Copy the **anon public** key
4. Paste both into `Shared/Constants.swift`:
   ```swift
   static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
   static let supabaseAnonKey = "YOUR_ANON_KEY"
   ```

### Enable Realtime
1. Go to **Database → Publications**
2. Make sure `supabase_realtime` publication includes:
   - `unlock_requests`
   - `pact_members`
   (The migration does this automatically, but verify)

## 2. Apple Developer Account

### Enrollment ($99/year)
1. Go to [developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll)
2. Sign in with your Apple ID
3. Complete identity verification (can take 24-48h, often instant)

### FamilyControls Entitlement
- **For development/testing on your device**: Works automatically with Xcode
- **For TestFlight/App Store**: You need to apply for the privileged entitlement at [developer.apple.com/contact/request/family-controls-distribution](https://developer.apple.com/contact/request/family-controls-distribution)
- Apple reviews these manually — explain your app's purpose

### Sign in with Apple Setup
1. Go to **Certificates, Identifiers & Profiles → Identifiers**
2. Find `com.lockin.app` (or create it)
3. Enable **Sign in with Apple** capability
4. Save

## 3. Xcode Setup

### Generate Project
```bash
cd ~/Desktop/REPOS/LockIn
xcodegen
open LockIn.xcodeproj
```

### Configure Signing
1. Select LockIn target → **Signing & Capabilities**
2. Set your **Team** (your Apple Developer account)
3. Repeat for all extension targets:
   - ShieldConfigurationExtension
   - ShieldActionExtension
   - DeviceActivityMonitorExtension

### Add Capabilities
These should already be set via entitlements, but verify:
- **Family Controls** capability on all 4 targets
- **App Groups** (`group.com.lockin.app`) on all 4 targets

### Test on Device
1. Plug in your iPhone via USB
2. Select your iPhone as the destination (not a simulator)
3. Build and run (Cmd+R)
4. Trust the developer certificate on your phone:
   Settings → General → VPN & Device Management → Trust

## 4. Push Notifications (Later)

Push notifications require:
1. An APNs key from Apple Developer portal
2. A Supabase Edge Function to send notifications
3. Registering device tokens in the app

This is a post-MVP task. The app works without push notifications — users just need to check the Requests tab manually for now.

## 5. Quick Test Checklist

- [ ] App launches with Sign in with Apple screen
- [ ] Can sign in and see home screen
- [ ] Can create a pact and get an invite code
- [ ] Can join a pact with an invite code (test with second account)
- [ ] Can select apps to lock via FamilyActivityPicker
- [ ] Locked apps show the custom shield overlay
- [ ] Can send unlock request
- [ ] Pact member sees the request and can approve/deny
