#!/bin/bash
# Builds the Flutter web app and deploys it to Vercel.
# Run this from the project root: ./deploy_web.sh
set -e
cd "$(dirname "$0")"
# --pwa-strategy=none disables the service worker: this app doesn't need
# offline support, and the SW was repeatedly serving stale cached builds
flutter build web --release --pwa-strategy=none
echo ".vercel" > build/web/.vercelignore
cd build/web
vercel --prod --yes
