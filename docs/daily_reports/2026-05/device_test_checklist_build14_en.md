# GoShopping Device Test Checklist - Build 14 (1.1.0+14)

**Test Date**: 2026-05-  **Tester**:
**Environment**: Android / iOS / Windows  **Flavor**: prod

---

## Priority Tests (Build 14 Fixes)

### 1. Single Mode - Default List Auto-Creation

- [ ] First group can be created after sign-up
- [ ] "Shopping List" is auto-created right after group creation
- [ ] Auto-created list is set as the current list
- [ ] Items can be added without a "please select a list" error
- [ ] Default list is also created via GroupCreationWithCopyDialog

### 2. Single Mode - FAB Grayed Out

- [ ] FABs are blue and enabled when no groups exist
- [ ] FABs turn gray after the first group is created
- [ ] Grayed-out create group FAB does nothing when tapped
- [ ] Grayed-out QR scan FAB does nothing when tapped
- [ ] In multi mode, FABs are always enabled

### 3. No Red Screen on First Group Creation

- [ ] No red screen when creating the first group after sign-up
- [ ] GroupListWidget displays correctly after group creation
- [ ] Empty state text is shown when no groups exist

### 4. Account Deletion Spinner Fix

- [ ] Spinner appears during account deletion
- [ ] Spinner closes automatically after deletion completes
- [ ] App navigates to sign-in screen after deletion
- [ ] Spinner does not get stuck when user cancels

### 5. Account Deletion Re-auth Dialog Overflow Fix

- [ ] Re-authentication dialog displays correctly
- [ ] No text or buttons overflow the screen
- [ ] Dialog is readable on small devices such as SH-54D

### 6. QR Invite Cross-Device Fix

- [ ] QR invite code can be generated on iOS
- [ ] QR code scanned on Android joins the group successfully
- [ ] No "invite not found" error after scanning
- [ ] Joined group appears in the group list
- [ ] Reverse direction works (Android generates, iOS scans)

### 7. Realtime Sync Fix (watchUserGroups)

- [ ] New group appears on other devices within 3 seconds
- [ ] Group name changes are reflected on other devices
- [ ] New member joining is reflected in the group list

---

## Regression Tests

### App Launch and Groups

- [ ] App launches within 3 seconds and restores previous state
- [ ] Groups can be created and deleted
- [ ] QR invite generation and scanning works
- [ ] Member list displays correctly

### Shopping List

- [ ] Lists can be created and deleted
- [ ] Items can be added, toggled, and deleted
- [ ] Item changes sync to other devices within 3 seconds

### Offline and Settings

- [ ] App works normally while offline and syncs on reconnect
- [ ] Display name can be changed and sign-out works
- [ ] Account deletion completes successfully

---

## Test Result Summary

| Area | Pass | Fail |
| --- | --- | --- |
| Single mode default list | / 5 | |
| FAB grayout | / 5 | |
| Red screen fix | / 3 | |
| Account deletion spinner | / 4 | |
| Re-auth dialog overflow | / 3 | |
| QR cross-device | / 5 | |
| Realtime sync | / 3 | |
| Regression | / 10 | |

---

## Issues Found

---

## Overall Result

- [ ] Pass
- [ ] Conditional pass (minor bugs, fix in next build)
- [ ] Fail (critical bugs, fix required)

Notes:
