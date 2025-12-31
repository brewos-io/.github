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

echo "🚀 Creating release..."
echo ""

# Check if we're on main branch and up to date (BEFORE any version changes)
check_repo_clean() {
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
    echo "  ❌ $name is not on main branch (current: $BRANCH)"
    echo "     Please switch to main branch before creating a release"
    return 1
  fi
  
  # Check for uncommitted changes (before version bump)
  if ! git diff-index --quiet HEAD --; then
    echo "  ❌ $name has uncommitted changes"
    echo "     Please commit or stash changes before creating a release"
    git status --short
    return 1
  fi
  
  # Pull latest
  echo "  📥 Pulling latest changes..."
  git pull origin main || true
  
  return 0
}

# Commit version changes in a repository
commit_version_changes() {
  local repo=$1
  local name=$2
  local version=$3
  
  if [ ! -d "$ROOT_DIR/$repo" ]; then
    return 1
  fi
  
  cd "$ROOT_DIR/$repo"
  
  if [ ! -d ".git" ]; then
    return 1
  fi
  
  # Check if there are any changes to commit
  if git diff-index --quiet HEAD --; then
    echo "  ℹ️  No changes to commit in $name"
    return 0
  fi
  
  # Stage all changes
  git add -A
  
  # Commit
  echo "  💾 Committing version changes..."
  git commit -m "chore: bump version to $version" || {
    echo "  ⚠️  Failed to commit in $name"
    return 1
  }
  
  echo "  ✓ Version changes committed in $name"
  return 0
}

# Create tag in repository (assumes we're already in the repo directory)
create_tag() {
  local tag_prefix=$1
  local name=$2
  
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

# Check all repos are clean BEFORE bumping
echo "🔍 Checking repositories are clean..."
echo ""

REPO_ERRORS=0

if [ -d "$ROOT_DIR/firmware" ]; then
  if ! check_repo_clean "firmware" "Firmware"; then
    REPO_ERRORS=$((REPO_ERRORS + 1))
  fi
fi

if [ -d "$ROOT_DIR/app" ]; then
  if ! check_repo_clean "app" "App"; then
    REPO_ERRORS=$((REPO_ERRORS + 1))
  fi
fi

if [ -d "$ROOT_DIR/cloud" ]; then
  if ! check_repo_clean "cloud" "Cloud"; then
    REPO_ERRORS=$((REPO_ERRORS + 1))
  fi
fi

if [ $REPO_ERRORS -gt 0 ]; then
  echo ""
  echo "❌ Some repositories have uncommitted changes or are not on main branch"
  echo "   Please fix the issues above before creating a release"
  exit 1
fi

echo ""
echo "✅ All repositories are clean"
echo ""

# Now bump versions (after confirming repos are clean)
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
  echo "✅ Version bumped to $VERSION"
  echo ""
elif [ -z "$VERSION" ]; then
  # If no version specified and not bumping, get current version
  VERSION=$(get_firmware_version)
  if [ -z "$VERSION" ]; then
    echo "Error: Could not determine version. Specify a version or use --bump"
    exit 1
  fi
  
  if [ -z "$MESSAGE" ]; then
    MESSAGE="Release $VERSION"
  fi
else
  # Specific version provided
  echo "📝 Setting versions to $VERSION..."
  "$SCRIPT_DIR/bump-version.sh" "$VERSION"
  echo ""
fi

echo "🚀 Creating release $VERSION..."
echo ""

echo ""
echo "💾 Committing version changes..."

# Commit version changes in each repo
if [ -d "$ROOT_DIR/firmware" ]; then
  commit_version_changes "firmware" "Firmware" "$VERSION"
fi

if [ -d "$ROOT_DIR/app" ]; then
  commit_version_changes "app" "App" "$VERSION"
fi

if [ -d "$ROOT_DIR/cloud" ]; then
  commit_version_changes "cloud" "Cloud" "$VERSION"
fi

echo ""
echo "📤 Pushing commits..."

# Push commits for each repo
push_commits() {
  local repo=$1
  local name=$2
  
  if [ ! -d "$ROOT_DIR/$repo" ] || [ ! -d "$ROOT_DIR/$repo/.git" ]; then
    return 1
  fi
  
  cd "$ROOT_DIR/$repo"
  
  # Check if there are commits to push
  if git rev-parse --verify "origin/main" >/dev/null 2>&1; then
    LOCAL=$(git rev-parse main)
    REMOTE=$(git rev-parse origin/main)
    if [ "$LOCAL" != "$REMOTE" ]; then
      echo "  📤 Pushing commits in $name..."
      git push origin main || {
        echo "  ⚠️  Failed to push commits in $name"
        return 1
      }
      echo "  ✓ Commits pushed in $name"
    else
      echo "  ℹ️  No commits to push in $name"
    fi
  else
    # First push - no remote main branch yet
    echo "  📤 Pushing commits in $name (first push)..."
    git push -u origin main || {
      echo "  ⚠️  Failed to push commits in $name"
      return 1
    }
    echo "  ✓ Commits pushed in $name"
  fi
  
  return 0
}

if [ -d "$ROOT_DIR/firmware" ]; then
  push_commits "firmware" "Firmware"
fi

if [ -d "$ROOT_DIR/app" ]; then
  push_commits "app" "App"
fi

if [ -d "$ROOT_DIR/cloud" ]; then
  push_commits "cloud" "Cloud"
fi

echo ""
echo "🏷️  Creating tags..."

# Firmware
if [ -d "$ROOT_DIR/firmware" ] && [ -d "$ROOT_DIR/firmware/.git" ]; then
  cd "$ROOT_DIR/firmware"
  create_tag "" "Firmware"
fi

# App
if [ -d "$ROOT_DIR/app" ] && [ -d "$ROOT_DIR/app/.git" ]; then
  cd "$ROOT_DIR/app"
  create_tag "app-" "App"
fi

# Cloud
if [ -d "$ROOT_DIR/cloud" ] && [ -d "$ROOT_DIR/cloud/.git" ]; then
  cd "$ROOT_DIR/cloud"
  create_tag "cloud-" "Cloud"
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


