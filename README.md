# CipherPath

<p align="center">
  <img src="CipherPath/Assets.xcassets/AppIcon.appiconset/CipherPathIcon.png" width="150" alt="CipherPath app icon">
</p>

**Apple-native cybersecurity learning app for iPhone.**

CipherPath is a SwiftUI project focused on legal, hands-on cybersecurity learning. It combines short offline lessons, guided practice, simulated labs, progress tracking, and defensive network tooling.

## Highlights

- structured learning paths covering security fundamentals, blue team, red team, web and mobile security
- guided lessons with knowledge checks, flags and explanations
- offline simulated labs with no public targets required
- progress, achievements, points and practice history
- local-network diagnostics and defensive tooling
- iSH and SSH-oriented workflows for controlled environments
- separate Developer and App Store distribution modes

## Distribution model

CipherPath keeps development-only functionality isolated from the App Store build.

- `CipherPath Dev` — development/testing scheme
- `CipherPath App Store` — production-oriented scheme
- separate bundle identifiers
- developer-only UI guarded at build time

This lets the public repository remain useful for development while the release configuration can later be submitted to App Store Connect.

## Stack

`Swift` · `SwiftUI` · `StoreKit 2` · `XCTest` · `iOS 17+` · `Network.framework`

## Run locally

1. Open `CipherPath.xcodeproj` in Xcode.
2. Select your own Apple Development Team.
3. Choose the Developer scheme for local development.
4. Run on a simulator or physical iPhone depending on the feature being tested.

## Security scope

CipherPath is intended for education, defensive testing, simulations, and systems you own or have explicit permission to test. The project does not require attacking public targets and does not include credential attacks or automatic exploit execution.

## Project status

Active development. App Store release is planned separately from the public source repository.

## License

Copyright © 2026 Krystian. All rights reserved. See [LICENSE](LICENSE).
