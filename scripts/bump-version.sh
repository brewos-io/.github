#!/bin/bash
# Bump version across all repositories
# Usage: 
#   ./scripts/bump-version.sh 0.2.0              # Set specific version
#   ./scripts/bump-version.sh --bump minor        # Bump minor version
#   ./scripts/bump-version.sh --bump major        # Bump major version
#   ./scripts/bump-version.sh --bump patch        # Bump patch version

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Parse arguments
BUMP_TYPE=""
VERSION=""

if [ "$1" == "--bump" ]; then
  BUMP_TYPE=$2
  if [ -z "$BUMP_TYPE" ]; then
    echo "Error: --bump requires a type (major, minor, or patch)"
    echo "Usage: $0 --bump <major|minor|patch>"
    exit 1
  fi
  if [[ ! "$BUMP_TYPE" =~ ^(major|minor|patch)$ ]]; then
    echo "Error: Invalid bump type. Use: major, minor, or patch"
    exit 1
  fi
elif [ -z "$1" ]; then
  echo "Usage: $0 <version> | --bump <major|minor|patch>"
  echo ""
  echo "Examples:"
  echo "  $0 0.2.0              # Set specific version"
  echo "  $0 --bump minor       # Bump minor version"
  echo "  $0 --bump major        # Bump major version"
  echo "  $0 --bump patch        # Bump patch version"
  exit 1
else
  VERSION=$1
  # Validate version format (semver)
  if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
    echo "Error: Invalid version format. Use semantic versioning (e.g., 0.2.0 or 0.2.0-beta.1)"
    exit 1
  fi
fi

# Get current firmware version (source of truth)
get_firmware_version() {
  if [ -d "$ROOT_DIR/firmware" ] && [ -f "$ROOT_DIR/firmware/VERSION" ]; then
    grep "^FIRMWARE_VERSION=" "$ROOT_DIR/firmware/VERSION" | cut -d'=' -f2
  else
    echo ""
  fi
}

# If bumping, get current version and calculate new version
if [ -n "$BUMP_TYPE" ]; then
  CURRENT_VERSION=$(get_firmware_version)
  if [ -z "$CURRENT_VERSION" ]; then
    echo "Error: Could not determine current firmware version"
    echo "Make sure firmware/VERSION file exists"
    exit 1
  fi
  
  echo "Current version: $CURRENT_VERSION"
  echo "Bumping $BUMP_TYPE version..."
  
  # Use version.js to calculate the new version
  cd "$ROOT_DIR/firmware"
  if [ -f "src/scripts/version.js" ]; then
    # Get the bumped version (dry run)
    VERSION=$(node src/scripts/version.js --bump "$BUMP_TYPE" 2>/dev/null | grep -E "^Bumped|^Firmware Version:" | tail -1 | sed 's/.*to //' | sed 's/Firmware Version: //' | tr -d ' ')
    if [ -z "$VERSION" ]; then
      # Fallback: parse version manually
      IFS='.' read -r major minor patch <<< "${CURRENT_VERSION%%-*}"
      case "$BUMP_TYPE" in
        major) major=$((major + 1)); minor=0; patch=0 ;;
        minor) minor=$((minor + 1)); patch=0 ;;
        patch) patch=$((patch + 1)) ;;
      esac
      VERSION="$major.$minor.$patch"
    fi
  else
    # Fallback: parse version manually
    IFS='.' read -r major minor patch <<< "${CURRENT_VERSION%%-*}"
    case "$BUMP_TYPE" in
      major) major=$((major + 1)); minor=0; patch=0 ;;
      minor) minor=$((minor + 1)); patch=0 ;;
      patch) patch=$((patch + 1)) ;;
    esac
    VERSION="$major.$minor.$patch"
  fi
  cd "$ROOT_DIR"
  
  echo "New version: $VERSION"
  echo ""
fi

echo "🔄 Bumping version to $VERSION across all repositories..."
echo ""

# Update firmware
if [ -d "$ROOT_DIR/firmware" ]; then
  echo "📦 Updating firmware version..."
  cd "$ROOT_DIR/firmware"
  
  # Use version.js script to update all firmware version files
  # This updates: VERSION, version.json, config.h files, protocol_defs.h, version-manifest.json
  if [ -f "src/scripts/version.js" ]; then
    if [ -n "$BUMP_TYPE" ]; then
      # Use --bump for firmware to ensure all files are updated correctly
      node src/scripts/version.js --bump "$BUMP_TYPE"
    else
      # Use --set for specific version
      node src/scripts/version.js --set "$VERSION"
    fi
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


