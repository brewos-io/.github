# Release Management & Versioning Strategy

This document describes the release management and versioning strategy for BrewOS repositories.

## Versioning Scheme

BrewOS uses **Semantic Versioning** (SemVer) with the format: `MAJOR.MINOR.PATCH[-PRERELEASE]`

### Version Components

- **MAJOR**: Breaking changes (API changes, protocol changes, incompatible updates)
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)
- **PRERELEASE**: Optional (alpha, beta, rc)

### Repository-Specific Tags

Each repository uses prefixed version tags:

| Repository   | Tag Format | Example                               |
| ------------ | ---------- | ------------------------------------- |
| **firmware** | `v*`       | `v0.2.0`, `v0.2.1-beta.1`             |
| **app**      | `app-v*`   | `app-v0.2.0`, `app-v0.2.1-beta.1`     |
| **cloud**    | `cloud-v*` | `cloud-v0.2.0`, `cloud-v0.2.1-beta.1` |

### Version Synchronization

For coordinated releases, use the **same version number** across repositories:

```
firmware:  v0.2.0
app:       app-v0.2.0
cloud:     cloud-v0.2.0
```

This ensures compatibility and makes it clear which versions work together.

## Release Types

### 1. Development Releases (Staging)

**Trigger:** Push to `main` branch

- **firmware**: Builds firmware, creates dev release artifacts
- **app**: Builds app artifacts (not deployed)
- **cloud**: Builds and deploys to staging server

**Purpose:** Test latest changes in staging environment

### 2. Stable Releases (Production)

**Trigger:** Version tag push (e.g., `v0.2.0`)

- **firmware**: Builds firmware, creates GitHub release
- **app**: Builds app artifacts, uploads to releases
- **cloud**: Deploys to production server

**Purpose:** Production-ready releases

### 3. Pre-releases (Beta/Alpha/RC)

**Trigger:** Pre-release tag (e.g., `v0.2.0-beta.1`)

- Same as stable releases but marked as pre-release
- Useful for testing before stable release

## Release Workflow

### Coordinated Release (Recommended)

For releases that span multiple repositories:

1. **Prepare Release**

   ```bash
   # Update versions in all repos
   # firmware: Update VERSION file
   # app: Update package.json
   # cloud: Update package.json
   ```

2. **Create Tags** (in order)

   ```bash
   # 1. Firmware (core)
   cd firmware
   git tag v0.2.0
   git push origin v0.2.0

   # 2. App (depends on firmware version)
   cd ../app
   git tag app-v0.2.0
   git push origin app-v0.2.0

   # 3. Cloud (depends on app version)
   cd ../cloud
   git tag cloud-v0.2.0
   git push origin cloud-v0.2.0
   ```

3. **Verify Deployments**
   - Check firmware release artifacts
   - Verify app builds
   - Confirm cloud production deployment

### Independent Release

Each repository can be released independently:

- **App-only release**: Tag `app-v0.2.1` (e.g., UI improvements)
- **Cloud-only release**: Tag `cloud-v0.2.1` (e.g., backend fixes)
- **Firmware-only release**: Tag `v0.2.1` (e.g., firmware bug fix)

## Version Management

### Firmware Repository

**Version Files:**

- `VERSION` - Main version file (used by build scripts)
- `version.json` - JSON version info
- `src/pico/include/config.h` - C header with version defines

**Update Process:**

```bash
# Recommended: Use version.js script (updates all files automatically)
cd firmware
node src/scripts/version.js --set 0.2.0

# Or for coordinated releases, use the root script:
cd ..  # from root
./scripts/bump-version.sh 0.2.0  # This calls version.js internally
```

The `version.js` script automatically updates:
- `VERSION` file
- `version.json`
- `src/pico/include/config.h` (Pico version defines)
- `src/esp32/include/config.h` (ESP32 version defines)
- `src/shared/protocol_defs.h` (Protocol version - use `--protocol` flag)
- `src/web/public/version-manifest.json` (OTA update manifest)

### App Repository

**Version Files:**

- `package.json` - npm package version

**Update Process:**

```bash
# Update package.json
npm version 0.2.0 --no-git-tag

# Or manually edit package.json
```

### Cloud Repository

**Version Files:**

- `package.json` - npm package version

**Update Process:**

```bash
# Update package.json
npm version 0.2.0 --no-git-tag

# Or manually edit package.json
```

## Release Checklist

### Pre-Release

- [ ] Update version numbers in all repositories
- [ ] Update CHANGELOG.md (if exists)
- [ ] Run tests locally
- [ ] Verify CI passes
- [ ] Review breaking changes
- [ ] Update documentation if needed

### Release

- [ ] Create version tags
- [ ] Push tags to trigger workflows
- [ ] Monitor workflow runs
- [ ] Verify artifacts are created
- [ ] Check staging deployment (if applicable)
- [ ] Verify production deployment

### Post-Release

- [ ] Verify GitHub releases are created
- [ ] Test production deployment
- [ ] Announce release (if applicable)
- [ ] Monitor for issues

## Version Compatibility Matrix

| Firmware | App        | Cloud        | Status                        |
| -------- | ---------- | ------------ | ----------------------------- |
| v0.2.0   | app-v0.2.0 | cloud-v0.2.0 | ✅ Compatible                 |
| v0.2.0   | app-v0.2.1 | cloud-v0.2.0 | ⚠️ May work (app update)      |
| v0.2.1   | app-v0.2.0 | cloud-v0.2.0 | ⚠️ May work (firmware update) |
| v0.3.0   | app-v0.2.0 | cloud-v0.2.0 | ❌ May break (major version)  |

**Rule of Thumb:** Keep major versions aligned. Minor/patch can differ but test compatibility.

## Automated Release Workflow

### GitHub Actions Integration

1. **Firmware Release** (`firmware/.github/workflows/release.yml`)

   - Triggered by `v*` tag
   - Builds firmware
   - Creates GitHub release
   - Uploads artifacts

2. **App Release** (`app/.github/workflows/release.yml`)

   - Triggered by `app-v*` tag
   - Builds app for cloud and ESP32
   - Uploads artifacts

3. **Cloud Release** (`cloud/.github/workflows/release.yml`)
   - Triggered by `cloud-v*` tag
   - Checks out matching app version
   - Builds and deploys to production

### Staging Deployments

- **Cloud**: Auto-deploys to staging on push to `main`
- **App**: Builds artifacts (not deployed)
- **Firmware**: Creates dev releases

## Rollback Procedure

### Cloud Service

```bash
# On production server
cd /root/brewos-cloud
git fetch origin --tags
git checkout cloud-v0.1.9  # Previous version
# Rebuild and restart
```

### Firmware

- Download previous firmware from GitHub releases
- Flash manually or via OTA

## Best Practices

1. **Version Coordination**: Use same version numbers for coordinated releases
2. **Test in Staging**: Always test in staging before production
3. **Semantic Versioning**: Follow SemVer strictly
4. **Changelog**: Document changes in releases
5. **Tagging**: Tag after merging to main, not before
6. **Pre-releases**: Use beta/alpha tags for testing
7. **Breaking Changes**: Increment major version
8. **Hotfixes**: Use patch version increments

## Version Bumping Script

Create a helper script for coordinated version bumps:

```bash
#!/bin/bash
# bump-version.sh
VERSION=$1

# Update firmware (version.js updates all files automatically)
cd firmware
node src/scripts/version.js --set $VERSION

# Update app
cd ../app
npm version $VERSION --no-git-tag

# Update cloud
cd ../cloud
npm version $VERSION --no-git-tag

echo "Versions updated to $VERSION"
echo "Review changes and commit"
```

## Troubleshooting

### Version Mismatch

If cloud deployment fails due to app version mismatch:

- Check if app version tag exists
- Cloud workflow falls back to `main` if tag not found
- Ensure app is tagged before cloud release

### Build Failures

- Check workflow logs
- Verify dependencies are up to date
- Ensure all secrets are configured
- Check server connectivity

### Deployment Issues

- Verify SSH keys and hostnames
- Check server disk space
- Review Docker logs
- Verify health check endpoints
