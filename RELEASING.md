# Releasing BotCrew

## One-time setup checklist

Complete these steps once before your first release.

### 1. Apple Developer ID certificate

1. Go to [developer.apple.com](https://developer.apple.com) → Certificates, Identifiers & Profiles
2. Create a **Developer ID Application** certificate (if you don't already have one)
3. Download and double-click to install in your login keychain
4. Open **Keychain Access**, find the cert, right-click → **Export Items...**
5. Save as `.p12`, set a strong password — you'll need both the file and password later

### 2. App-specific password for notarization

1. Go to [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords
2. Click **Generate an app-specific password**
3. Label it "BotCrew Notarization"
4. Copy the generated password — this is NOT your Apple ID password

### 3. Find your Team ID

Go to [developer.apple.com](https://developer.apple.com) → Account → Membership details.
Your **Team ID** is a 10-character alphanumeric string.

### 4. Add GitHub Secrets

Go to your repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

Add all 5:

| Secret | How to get the value |
|--------|---------------------|
| `DEVELOPER_ID_CERTIFICATE_P12` | Run `base64 -i YourCert.p12 \| pbcopy` and paste |
| `DEVELOPER_ID_CERTIFICATE_PASSWORD` | The password you set when exporting the .p12 |
| `APPLE_ID` | Your Apple ID email address |
| `APPLE_ID_PASSWORD` | The app-specific password from step 2 (NOT your account password) |
| `APPLE_TEAM_ID` | 10-character Team ID from step 3 |

### 5. Enable GitHub Actions write permissions

Your repo → **Settings** → **Actions** → **General** → scroll to **Workflow permissions** → select **Read and write permissions** → Save.

---

## Cutting a release

### 1. Bump the version

Edit `project.yml`:

```yaml
CURRENT_PROJECT_VERSION: 2        # increment by 1 each release
MARKETING_VERSION: 0.2.0          # semver shown to users
```

### 2. Commit and tag

```bash
git add project.yml
git commit -m "Bump to v0.2.0"
git tag v0.2.0
git push origin main --tags
```

### 3. Wait for CI

The GitHub Actions workflow runs automatically on tag push. It takes ~15-20 minutes and will:

1. Build the app in Release configuration
2. Code-sign with your Developer ID certificate
3. Notarize the .app with Apple (~5-15 min)
4. Package into `BotCrew-0.2.0.dmg`
5. Notarize the DMG with Apple
6. Create a **GitHub Release** with the DMG attached and auto-generated release notes

### 4. Verify

- Check the [Actions tab](https://github.com/briansanders/botcrew/actions) for a green workflow run
- Check the [Releases page](https://github.com/briansanders/botcrew/releases) for the new release with DMG

---

## How users get the app

Download the latest DMG from the [Releases page](https://github.com/briansanders/botcrew/releases). Open the DMG, drag BotCrew to Applications.

---

## Troubleshooting

### Notarization fails
- Verify your app-specific password hasn't expired (they can be revoked at appleid.apple.com)
- Check that Hardened Runtime is enabled (`ENABLE_HARDENED_RUNTIME: YES` in project.yml)
- Review the notarization log: `xcrun notarytool log <submission-id> --apple-id ... --team-id ...`

### Code signing fails in CI
- Re-export your .p12 and update the `DEVELOPER_ID_CERTIFICATE_P12` secret
- Make sure the certificate hasn't expired (they last 5 years)
- Check that `APPLE_TEAM_ID` matches the team that issued the cert

### Build number ordering
Always increment `CURRENT_PROJECT_VERSION` — even for patch releases. `MARKETING_VERSION` is display-only.
