---
layout: page
title: iOS Setup
---

# iOS Setup

## Firebase

Add `GoogleService-Info.plist` to `ios/Runner/` and ensure Firebase is configured in the host app.

## APNs

Push delivery on physical iOS devices requires:

- Push Notifications capability
- Background Modes with remote notifications
- Valid APNs setup in Apple Developer and Firebase

## Permissions

Request notification permissions during initialization or via the permission APIs exposed by the package.

## Validation

Use the example app or `runDiagnostics()` to confirm permission state, token availability, and background wiring.
