#!/bin/bash
# Bump version across all repositories
# Usage: ./scripts/bump-version.sh 0.2.0

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 0.2.0"
  exit 1
fi

# Validate version format (semver)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
  echo "Error: Invalid version format. Use semantic versioning (e.g., 0.2.0 or 0.2.0-beta.1)"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔄 Bumping version to $VERSION across all repositories..."
echo ""

# Update firmware
if [ -d "$ROOT_DIR/firmware" ]; then
  echo "📦 Updating firmware version..."
  cd "$ROOT_DIR/firmware"
  
  # Use version.js script to update all firmware version files
  # This updates: VERSION, version.json, config.h files, protocol_defs.h, version-manifest.json
  if [ -f "src/scripts/version.js" ]; then
    node src/scripts/version.js --set "$VERSION"
    echo "  ✓ Firmware version updated (all files)"
  else
    # Fallback to manual update if version.js doesn't exist
    echo "  ⚠️  version.js not found, using manual update"
    sed -i.bak "s/^FIRMWARE_VERSION=.*/FIRMWARE_VERSION=$VERSION/" VERSION
    rm -f VERSION.bak
    
    if [ -f "version.json" ]; then
      node -e "
        const fs = require('fs');
        const json = JSON.parse(fs.readFileSync('version.json', 'utf8'));
        json.version = '$VERSION';
        json.updatedAt = new Date().toISOString();
        fs.writeFileSync('version.json', JSON.stringify(json, null, 2) + '\n');
      "
    fi
    echo "  ✓ Firmware version updated (basic files only)"
  fi
else
  echo "  ⚠️  Firmware directory not found, skipping"
fi

# Update app
if [ -d "$ROOT_DIR/app" ]; then
  echo "📱 Updating app version..."
  cd "$ROOT_DIR/app"
  
  # Update package.json
  npm version "$VERSION" --no-git-tag --allow-same-version 2>/dev/null || \
    node -e "
      const fs = require('fs');
      const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      pkg.version = '$VERSION';
      fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
    "
  
  echo "  ✓ App version updated"
else
  echo "  ⚠️  App directory not found, skipping"
fi

# Update cloud
if [ -d "$ROOT_DIR/cloud" ]; then
  echo "☁️  Updating cloud version..."
  cd "$ROOT_DIR/cloud"
  
  # Update package.json
  npm version "$VERSION" --no-git-tag --allow-same-version 2>/dev/null || \
    node -e "
      const fs = require('fs');
      const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      pkg.version = '$VERSION';
      fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
    "
  
  echo "  ✓ Cloud version updated"
else
  echo "  ⚠️  Cloud directory not found, skipping"
fi

echo ""
echo "✅ Version bumped to $VERSION"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Commit changes: git commit -am \"Bump version to $VERSION\""
echo "  3. Create tags:"
echo "     - firmware: git tag v$VERSION"
echo "     - app: git tag app-v$VERSION"
echo "     - cloud: git tag cloud-v$VERSION"
echo "  4. Push tags: git push origin --tags"


