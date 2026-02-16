#!/bin/bash

# Exit on error
set -e

# Define Flutter version/channel
FLUTTER_CHANNEL="stable"

echo "--- Installing Flutter ---"
# Download Flutter
git clone https://github.com/flutter/flutter.git -b $FLUTTER_CHANNEL

# Update PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Initialization
flutter doctor -v

echo "--- Building for Web ---"
# Build the web app
flutter build web --release --no-tree-shake-icons

echo "--- Build Complete ---"
