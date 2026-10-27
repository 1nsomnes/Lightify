#!/usr/bin/env bash
# Builds a signed, notarized DMG of Lightify for GitHub Releases.
#
#   scripts/release.sh            # version from pubspec.yaml
#
# One-time setup:
#   - "Developer ID Application" certificate in the login keychain
#   - Xcode signed into the Apple account (Settings → Accounts), so it can
#     create the Developer ID provisioning profile
#   - notary credentials: xcrun notarytool store-credentials lightify-notary \
#       --apple-id <apple id> --team-id A2666RLPH7
#   - create-dmg: npm install -g create-dmg
set -euo pipefail

cd "$(dirname "$0")/.."

NOTARY_PROFILE="lightify-notary"
OUT="build/release"
ARCHIVE="$OUT/Lightify.xcarchive"
EXPORT="$OUT/export"

version=$(sed -n 's/^version: *//p' pubspec.yaml)
echo "==> Building Lightify $version"

rm -rf "$OUT"
mkdir -p "$OUT"

# compiles the Dart code and writes the version into the Xcode config
flutter build macos --release

# archive and re-sign with Developer ID (hardened runtime is on for Release)
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
  -configuration Release -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates archive | tail -n 3
xcodebuild -exportArchive -archivePath "$ARCHIVE" \
  -exportOptionsPlist macos/ExportOptions.plist -exportPath "$EXPORT" \
  -allowProvisioningUpdates | tail -n 3

app=$(find "$EXPORT" -maxdepth 1 -name "*.app" | head -n 1)
codesign --verify --strict --deep "$app"
echo "==> Signed $app"

# create-dmg signs the DMG with the Developer ID identity it finds
create-dmg "$app" "$OUT" --overwrite
dmg=$(find "$OUT" -maxdepth 1 -name "*.dmg" | head -n 1)

echo "==> Notarizing $dmg (this takes a few minutes)"
xcrun notarytool submit "$dmg" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$dmg"
spctl --assess --type open --context context:primary-signature -v "$dmg"

echo "==> Done: $dmg"
echo "    Publish: gh release create v${version%%+*} \"$dmg\""
