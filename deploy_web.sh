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
# `flutter clean` wipes build/web, including the .vercel project link file.
# Without it, `vercel --prod` creates a brand-new stray project instead of
# updating the real one - re-link explicitly if that's happened.
if [ ! -f .vercel/project.json ]; then
  vercel link --yes --project=auraly-voice-assistant
fi
vercel --prod --yes
