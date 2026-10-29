#!/bin/zsh
# Builds a Developer ID signed, notarized and stapled OfficeLight.app and zips it for a GitHub release.
#
# One-time setup:
#   1. A "Developer ID Application" certificate in your keychain
#      (Xcode → Settings → Accounts → Manage Certificates).
#   2. Notarization credentials stored in the keychain:
#        xcrun notarytool store-credentials OfficeLight --apple-id you@example.com --team-id ABCDE12345
#
# Usage:
#   DEVELOPMENT_TEAM=ABCDE12345 scripts/release.sh
#   NOTARY_PROFILE overrides the keychain profile name (default: OfficeLight).
set -euo pipefail

cd "$(dirname "$0")/.."
: "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM to your Apple team ID}"
profile="${NOTARY_PROFILE:-OfficeLight}"

out=build/release
rm -rf "$out"
mkdir -p "$out"

cat > "$out/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>developer-id</string>
	<key>teamID</key>
	<string>$DEVELOPMENT_TEAM</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>destination</key>
	<string>export</string>
</dict>
</plist>
PLIST

echo "Archiving…"
xcodebuild -project OfficeLight.xcodeproj -scheme OfficeLight -configuration Release -quiet \
  -derivedDataPath build -archivePath "$out/OfficeLight.xcarchive" \
  "CODE_SIGN_IDENTITY=Apple Development" "DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM" archive

echo "Exporting with Developer ID…"
xcodebuild -quiet -exportArchive -allowProvisioningUpdates \
  -archivePath "$out/OfficeLight.xcarchive" \
  -exportOptionsPlist "$out/ExportOptions.plist" -exportPath "$out/export"

app="$out/export/OfficeLight.app"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")
zip="$out/OfficeLight-$version.zip"

echo "Notarizing…"
ditto -c -k --keepParent "$app" "$zip"
xcrun notarytool submit "$zip" --keychain-profile "$profile" --wait
xcrun stapler staple "$app"

# Re-zip so the download carries the stapled ticket and opens without a network round trip.
rm "$zip"
ditto -c -k --keepParent "$app" "$zip"
spctl --assess --type execute --verbose=2 "$app"

echo
echo "Release build: $zip"
echo "Next: git tag v$version && git push --tags, then attach the zip to the GitHub release."
