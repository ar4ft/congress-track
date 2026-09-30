# Signed, notarized releases and automatic updates

The app and release workflow are implemented. **A production release cannot be issued until you configure the Apple and Sparkle credentials below.** Development jobs never invoke certificate signing or notarization, and have automatic updates disabled. Signing is permitted only in an explicitly selected, manually started release action.

The pipeline uses a Developer ID Application certificate, an App Store Connect **team** API key authorized for notarization, and a Sparkle Ed25519 signing key. It builds a universal app for Intel and Apple silicon; signs all nested Sparkle code with your identity; notarizes and staples the app and DMG; signs and verifies the update archive and feed; and uploads everything to a draft GitHub Release before publishing it. It rejects missing credentials, mismatched keys, reused versions, build-number downgrades, and unaccepted notarization results.

## 1. Create and export your Developer ID certificate on a Mac

1. In Xcode, open **Settings → Accounts**, add your Apple Developer account, select the paid team, and open **Manage Certificates**.
2. Create a **Developer ID Application** certificate. Use this certificate type, not Apple Development, Apple Distribution, or Developer ID Installer. Developer ID Application signs this app and DMG; no PKG installer is used.
3. In **Keychain Access → My Certificates**, find `Developer ID Application: Your Name (TEAMID)`. Expand it and confirm the private key exists. Export the certificate **and private key** as `DeveloperID.p12`, with an export password.
4. Note the ten-character team ID in parentheses. If Xcode cannot create the certificate, your team's account holder/admin may need to grant access or create it using a CSR from your Mac. Apple's account portal is https://developer.apple.com/account/resources/certificates/list.

Keep the original private key and P12 backup secure. Do not commit or send either through chat.

## 2. Create a notarization API key

In [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api), create a **team API key** permitted to use notarization. API access may need to be enabled by your account holder. Keep the **Key ID**, **Issuer ID**, and downloaded `AuthKey_KEYID.p8`. Apple permits downloading the private key only once.

This workflow uses a team key with issuer ID. Individual API keys and Apple ID app-specific passwords are not configured in this pipeline. `notarytool store-credentials` validates your configured API credentials before any build is published.

## 3. Generate the production Sparkle key once

On your Mac, from a checkout of this repository:

```bash
swift package resolve
.build/artifacts/sparkle/Sparkle/bin/generate_keys
.build/artifacts/sparkle/Sparkle/bin/generate_keys -p
.build/artifacts/sparkle/Sparkle/bin/generate_keys -x "$PWD/sparkle-private-key"
```

Sparkle stores its key in your login keychain. `-p` prints the **public key**, which is safe to share. `-x` exports the **private seed**, which must remain secret. Sparkle 2.10 creates a 32-byte private seed encoded as base64; the release checks require this current format. If an existing key is in the older format, use a separate account for a fresh key and pass that same account to each command, for example `--account congresstrack`. Do not replace a production key after releases have shipped without planning a supported key rotation.

Back up the production key. Losing it interrupts updates; a repository change alone cannot rotate the key trusted by installed applications.

## 4. Configure GitHub Actions

Open [repository Actions settings](https://github.com/ar4ft/congress-track/settings/secrets/actions). Create these **repository secrets**:

| Secret | Value |
| --- | --- |
| `MACOS_CERTIFICATE_BASE64` | Base64-encoded bytes of `DeveloperID.p12` |
| `MACOS_CERTIFICATE_PASSWORD` | The P12 export password |
| `APPLE_API_PRIVATE_KEY` | Complete text of the downloaded P8 file |
| `SPARKLE_PRIVATE_KEY` | Complete text of Sparkle's exported private-key file |

Create these **repository variables** in the Variables tab:

| Variable | Value |
| --- | --- |
| `APPLE_TEAM_ID` | Team ID matching your Developer ID certificate |
| `APPLE_API_KEY_ID` | App Store Connect API Key ID |
| `APPLE_API_ISSUER_ID` | App Store Connect API Issuer ID |
| `SPARKLE_PUBLIC_KEY` | Base64 public key printed by `generate_keys -p` |

Alternatively, configure them with the GitHub CLI **on your Mac**, authenticated with repository settings access:

```bash
base64 < DeveloperID.p12 | gh secret set MACOS_CERTIFICATE_BASE64 --repo ar4ft/congress-track
gh secret set MACOS_CERTIFICATE_PASSWORD --repo ar4ft/congress-track
gh secret set APPLE_API_PRIVATE_KEY --repo ar4ft/congress-track < AuthKey_KEYID.p8
gh secret set SPARKLE_PRIVATE_KEY --repo ar4ft/congress-track < sparkle-private-key

gh variable set APPLE_TEAM_ID --repo ar4ft/congress-track --body 'YOUR_TEAM_ID'
gh variable set APPLE_API_KEY_ID --repo ar4ft/congress-track --body 'YOUR_KEY_ID'
gh variable set APPLE_API_ISSUER_ID --repo ar4ft/congress-track --body 'YOUR_ISSUER_ID'
.build/artifacts/sparkle/Sparkle/bin/generate_keys -p | gh variable set SPARKLE_PUBLIC_KEY --repo ar4ft/congress-track
```

`gh secret set MACOS_CERTIFICATE_PASSWORD` prompts for the password; avoid passing it as a command-line argument. After storing the private key, move its exported file into your secure backup location. The repository ignores P12/P8 files and `sparkle-private-key*`, but you should still keep them outside the checkout.

The current agent's GitHub connection cannot inspect/manage Actions secrets. Configure these through GitHub settings or your own GitHub CLI; do not paste private credentials into the conversation. The workflow imports them into a temporary keychain and restricted files, then removes them even on failure. Secrets are never included in distributable artifacts.

## 5. Publish the first production release

`Release.json` is the single source of version/build metadata. The first updater-enabled release is **0.3.0, build 3**. Both fields must increase for subsequent releases. After the main CI run passes and the credentials are configured, create a matching tag:

```bash
git tag v0.3.0
git push origin v0.3.0
```

Creating or pushing the tag **does not sign or publish anything**. Open **Actions → Mac build or signed release → Run workflow**, enter `v0.3.0` in the tag field, and check **Sign, notarize, and publish a production release**. Only this manual selection enables signing/notarization and publishing.

For a development build, leave that checkbox off. The default is off. Leave the tag field blank to build the selected branch, or enter another existing branch/tag. This mode builds downloadable development artifacts without release signing, notarization, or publication; no Apple credentials are needed. Ordinary pushes and pull requests also run development CI without signing.

Retry a failed production release by manually running the same tag with the checkbox on. The job can resume an incomplete draft but will not overwrite a published release. No production tag or release was created during implementation because signing setup is still required.

The release contains `CongressTrack.dmg`, `CongressTrack-macOS.zip`, `appcast.xml`, `release-metadata.json`, and `SHA256SUMS`. Debug symbols are stored in a separate Actions artifact. The DMG includes an Applications shortcut; users drag the app to Applications.

The latest release's feed lives at:

```text
https://github.com/ar4ft/congress-track/releases/latest/download/appcast.xml
```

Its archive URL points to an immutable, versioned release. Only the final publish step switches the latest feed. Production releases stay public so users can download updates without GitHub authentication. Do not edit signed appcasts or replace update archives after publication.

## 6. Verify the first real update

Existing 0.2 development builds have no updater and need a **one-time manual install** of 0.3.0. Production builds check daily and enable automatic downloads/install-on-quit; users can turn either off in Settings. **Check for Updates…** is available in the app menu and menu bar. Sparkle installs the new application while keeping UserDefaults and Application Support data.

For a complete production test, install notarized 0.3.0 in Applications, publish a new version/build such as 0.3.1/build 4, and use Check for Updates from the old copy. Verify the offered version, installation/relaunch, and retained watchlists. The first release alone cannot test a real version-to-version upgrade.

CI tests the universal development app and Sparkle-generated archive/feed signatures using an ephemeral test key, then verifies altered archives/feeds are rejected. Those temporary fixtures are not distributed and no binaries are code signed in that test. Those tests do **not** substitute for Apple notarization or this first installed-app upgrade test.

## Development-signature details

Development workflows do not run `codesign`, use Apple credentials, or submit anything to Apple. The Swift/macOS linker may include a platform-required ad hoc signature in an executable, particularly on Apple silicon; that does not use your Developer ID identity or certify a release. Sparkle also arrives with its upstream vendor signature, which is preserved in development builds. Only the manual production job re-signs the app, framework, helpers, and installer using your certificate.
