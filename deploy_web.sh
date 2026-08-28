#!/bin/bash
# Builds the Flutter web app and deploys it to Vercel.
# Run this from the project root: ./deploy_web.sh
set -e
cd "$(dirname "$0")"
flutter build web --release
echo ".vercel" > build/web/.vercelignore
cd build/web
vercel --prod --yes
