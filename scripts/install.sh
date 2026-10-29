#!/bin/zsh
# Builds Office Light (Release) and installs it to ~/Applications.
# The Location Services and login item permissions are tied to this path and to the code signature.
#
# By default the app is ad-hoc signed, so macOS asks for the permissions again after every rebuild.
# Set DEVELOPMENT_TEAM to your Apple team ID to sign with your Apple Development certificate instead:
#   DEVELOPMENT_TEAM=ABCDE12345 scripts/install.sh
set -euo pipefail

cd "$(dirname "$0")/.."
target="$HOME/Applications/OfficeLight.app"

signing=()
if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then
  signing=("CODE_SIGN_IDENTITY=Apple Development" "DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM")
fi

xcodebuild -project OfficeLight.xcodeproj -scheme OfficeLight -configuration Release \
  -derivedDataPath build -quiet "${signing[@]}" build

pkill -x OfficeLight || true
mkdir -p "$HOME/Applications"
rm -rf "$target"
cp -R build/Build/Products/Release/OfficeLight.app "$target"
open "$target"
echo "Installed: $target"
