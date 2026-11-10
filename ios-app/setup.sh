#!/bin/bash
# Run once on your Mac from this folder:  bash setup.sh
set -e
cd "$(dirname "$0")"
command -v npm >/dev/null || { echo "Node.js is needed: install it from https://nodejs.org (LTS), then run this again."; exit 1; }
npm install
npx cap sync ios
open ios/App/App.xcodeproj
echo "Xcode is opening. Follow the steps in README.md (Signing & Capabilities -> Team, then Run)."
