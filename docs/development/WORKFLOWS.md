# GitHub Actions Workflows

This document describes the GitHub Actions workflows across all BrewOS repositories.

## Repository Structure

- **firmware** - ESP32 and Pico firmware
- **app** - Progressive Web App (shared between ESP32 and cloud)
- **cloud** - Cloud service for remote access
- **web** - Marketing website
- **homeassistant** - Home Assistant integration

## Workflow Overview

### Firmware Repository

**Location:** `firmware/.github/workflows/`

#### `ci.yml` - Continuous Integration

- Runs on PRs to `main`
- Detects changes to Pico or ESP32 code
- **Pico:** Runs unit tests and builds all machine types
- **ESP32:** Checks out app repository and builds app for ESP32, then builds ESP32 firmware

#### `build_firmware.yml` - Firmware Build & Test

- Runs on PRs affecting firmware code
- Tests Pico firmware
- Builds all Pico machine types (dual boiler, single boiler, heat exchanger)
- Uploads firmware artifacts

#### `release.yml` - Release Build

- Triggered on version tags (e.g., `v0.2.0`)
- Builds Pico firmware for all machine types
- Checks out app repository and builds app for ESP32
- Builds ESP32 firmware and LittleFS image
- Creates GitHub release with firmware artifacts
- **Note:** Cloud deployment is handled by cloud repository

### App Repository

**Location:** `app/.github/workflows/`

#### `ci.yml` - Continuous Integration

- Runs on PRs to `main`
- Lints code
- Type checks TypeScript
- Builds for both cloud and ESP32 targets
- Uploads build artifacts

#### `trigger-cloud-staging.yml` - Trigger Cloud Staging Deployment

- Runs on push to `main` (when app code changes)
- Triggers cloud repository's staging deployment workflow via `repository_dispatch`
- Allows staging to deploy automatically when app changes, even though repos are separate

#### `release.yml` - Release Build

- Triggered on version tags (e.g., `app-v0.2.0`)
- Builds app for cloud and ESP32
- Uploads build artifacts

### Cloud Repository

**Location:** `cloud/.github/workflows/`

#### `ci.yml` - Continuous Integration

- Runs on PRs to `main`
- Lints code
- Type checks TypeScript (cloud service and admin UI)
- Builds cloud service and admin UI
- Uploads build artifacts

#### `deploy-staging.yml` - Deploy to Staging

- Runs on push to `main` (when cloud code changes) OR `repository_dispatch` (when app code changes)
- When triggered by cloud changes: Verifies cloud build, then waits for app build
- When triggered by app changes: Skips cloud build check, waits for app build
- Checks out app repository
- Builds app for cloud
- Deploys to staging server
- Health checks after deployment

#### `release.yml` - Deploy to Production

- Triggered on version tags (e.g., `cloud-v0.2.0`)
- Checks out app repository (tries to match version tag, falls back to main)
- Builds app for cloud
- Deploys to production server
- Health checks after deployment

### Web Repository

**Location:** `web/.github/workflows/`

#### `pages.yml` - Deploy to GitHub Pages

- Runs on push to `main`
- Builds Astro site
- Deploys to GitHub Pages

## Version Tagging Strategy

Each repository uses its own version tags:

- **firmware:** `v0.2.0` (firmware releases)
- **app:** `app-v0.2.0` (app releases)
- **cloud:** `cloud-v0.2.0` (cloud service releases)

When releasing:

1. Tag firmware with `v0.2.0` → builds and releases firmware
2. Tag app with `app-v0.2.0` → builds app artifacts
3. Tag cloud with `cloud-v0.2.0` → deploys to production (uses matching app version if available)

## Cross-Repository Dependencies

### Firmware → App

- Firmware workflows checkout app repository when building ESP32 firmware
- Uses `actions/checkout@v6` with `repository: brewos-io/app`

### Cloud → App

- Cloud workflows checkout app repository when deploying
- Tries to match version tags (e.g., `cloud-v0.2.0` → `app-v0.2.0`)
- Falls back to `main` if matching version not found

### App → Cloud

- App workflow triggers cloud staging deployment via `repository_dispatch` when app changes are pushed to `main`
- Cloud workflow accepts `deploy-staging` repository_dispatch events
- This enables automatic staging deployment when app code changes, even though repos are separate

## Secrets Required

### Firmware Repository

- `GITHUB_TOKEN` (automatically provided) - for checking out app repository

### Cloud Repository

- `GOOGLE_CLIENT_ID` - Google OAuth client ID
- `STAGING_SSH_HOST` - Staging server hostname
- `STAGING_SERVER_SSH_KEY` - SSH key for staging server
- `SERVER_SSH_HOST` - Production server hostname
- `SERVER_SSH_KEY` - SSH key for production server

## Best Practices

1. **Version Coordination:** When releasing, ensure app and cloud versions are coordinated
2. **Testing:** Always test in staging before production deployment
3. **Health Checks:** All deployment workflows include health checks
4. **Artifacts:** Build artifacts are uploaded for debugging and manual deployments
5. **Caching:** npm dependencies are cached to speed up builds

## Troubleshooting

### App build fails in firmware workflow

- Check that app repository is accessible
- Verify `GITHUB_TOKEN` has permissions to read app repository

### Cloud deployment fails

- Check that app repository is accessible
- Verify app version tag matches cloud version tag (or main branch is up to date)
- Check server SSH keys and hostnames in secrets

### Version mismatch

- Ensure version tags follow the pattern: `v*`, `app-v*`, `cloud-v*`
- Cloud workflow will use main branch if matching app version not found
