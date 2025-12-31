#!/bin/bash
# Create coordinated release across all repositories
# Usage: 
#   ./scripts/create-release.sh 0.2.0 [message]           # Set specific version
#   ./scripts/create-release.sh --bump minor [message]   # Bump minor and release
#   ./scripts/create-release.sh --bump major [message]    # Bump major and release

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Parse arguments
BUMP_TYPE=""
VERSION=""
MESSAGE=""

if [ "$1" == "--bump" ]; then
  BUMP_TYPE=$2
  MESSAGE=${3:-""}
  if [ -z "$BUMP_TYPE" ]; then
    echo "Error: --bump requires a type (major, minor, or patch)"
    echo "Usage: $0 --bump <major|minor|patch> [message]"
    exit 1
  fi
  if [[ ! "$BUMP_TYPE" =~ ^(major|minor|patch)$ ]]; then
    echo "Error: Invalid bump type. Use: major, minor, or patch"
    exit 1
  fi
elif [ -z "$1" ]; then
  echo "Usage: $0 <version> [message] | --bump <major|minor|patch> [message]"
  echo ""
  echo "Examples:"
  echo "  $0 0.2.0 \"Release message\"           # Set specific version"
  echo "  $0 --bump minor \"Release message\"    # Bump minor version"
  echo "  $0 --bump major \"Release message\"    # Bump major version"
  exit 1
else
  VERSION=$1
  MESSAGE=${2:-"Release $VERSION"}
  # Validate version format
  if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
    echo "Error: Invalid version format. Use semantic versioning (e.g., 0.2.0)"
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

# If bumping, first bump versions, then get the new version
if [ -n "$BUMP_TYPE" ]; then
  echo "🔄 Bumping $BUMP_TYPE version..."
  "$SCRIPT_DIR/bump-version.sh" --bump "$BUMP_TYPE"
  
  # Get the new version after bumping
  VERSION=$(get_firmware_version)
  if [ -z "$VERSION" ]; then
    echo "Error: Could not determine version after bump"
    exit 1
  fi
  
  if [ -z "$MESSAGE" ]; then
    MESSAGE="Release $VERSION"
  fi
  
  echo ""
fi

echo "🚀 Creating release $VERSION..."
echo ""

# Check if we're on main branch and up to date
check_repo() {
  local repo=$1
  local name=$2
  
  if [ ! -d "$ROOT_DIR/$repo" ]; then
    echo "  ⚠️  $name directory not found, skipping"
    return 1
  fi
  
  cd "$ROOT_DIR/$repo"
  
  # Check if git repo
  if [ ! -d ".git" ]; then
    echo "  ⚠️  $name is not a git repository, skipping"
    return 1
  fi
  
  # Check branch
  BRANCH=$(git branch --show-current)
  if [ "$BRANCH" != "main" ]; then
    echo "  ⚠️  $name is not on main branch (current: $BRANCH)"
    read -p "  Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      return 1
    fi
  fi
  
  # Check for uncommitted changes
  if ! git diff-index --quiet HEAD --; then
    echo "  ⚠️  $name has uncommitted changes"
    read -p "  Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      return 1
    fi
  fi
  
  # Pull latest
  echo "  📥 Pulling latest changes..."
  git pull origin main || true
  
  return 0
}

# Create tag in repository
create_tag() {
  local repo=$1
  local tag_prefix=$2
  local name=$3
  
  if [ ! -d "$ROOT_DIR/$repo" ]; then
    return 1
  fi
  
  cd "$ROOT_DIR/$repo"
  
  if [ ! -d ".git" ]; then
    return 1
  fi
  
  local tag="${tag_prefix}v${VERSION}"
  
  # Check if tag already exists
  if git rev-parse "$tag" >/dev/null 2>&1; then
    echo "  ⚠️  Tag $tag already exists in $name"
    read -p "  Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      return 1
    fi
    git tag -d "$tag" || true
    git push origin ":refs/tags/$tag" || true
  fi
  
  echo "  🏷️  Creating tag $tag..."
  git tag -a "$tag" -m "$MESSAGE"
  
  echo "  📤 Pushing tag..."
  git push origin "$tag"
  
  echo "  ✓ $name tagged as $tag"
  return 0
}

# Bump versions first (if not already bumped)
if [ -z "$BUMP_TYPE" ]; then
  echo "📝 Bumping versions..."
  "$SCRIPT_DIR/bump-version.sh" "$VERSION"
fi

echo ""
echo "🏷️  Creating tags..."

# Firmware
if check_repo "firmware" "Firmware"; then
  create_tag "firmware" "" "Firmware"
fi

# App
if check_repo "app" "App"; then
  create_tag "app" "app-" "App"
fi

# Cloud
if check_repo "cloud" "Cloud"; then
  create_tag "cloud" "cloud-" "Cloud"
fi

echo ""
echo "✅ Release $VERSION created!"
echo ""
echo "GitHub Actions will now:"
echo "  - Build firmware and create release"
echo "  - Build app artifacts"
echo "  - Deploy cloud to production"
echo ""
echo "Monitor workflows at:"
echo "  - https://github.com/brewos-io/firmware/actions"
echo "  - https://github.com/brewos-io/app/actions"
echo "  - https://github.com/brewos-io/cloud/actions"


