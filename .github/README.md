# BrewOS Organization GitHub Configuration

This directory contains organization-level GitHub configuration files.

## Contents

- **coordinated-release.yml** - Workflow for coordinated releases across repositories

## Documentation

All documentation has been moved to the `docs/` folder:

- **[Documentation Index](../docs/README.md)** - Complete documentation guide
- **[Workflows Documentation](../docs/development/WORKFLOWS.md)** - GitHub Actions workflows
- **[Release Management](../docs/deployment/RELEASE_MANAGEMENT.md)** - Versioning and releases
- **[Secrets Configuration](../docs/deployment/SECRETS.md)** - Required GitHub secrets

## Scripts

Helper scripts are available in the root `scripts/` directory:

- `bump-version.sh` - Bump version across all repositories
- `create-release.sh` - Create coordinated release with tags

## Getting Started

### Creating a Release

1. **Manual Method:**
   ```bash
   # Bump versions
   ./scripts/bump-version.sh 0.2.0
   
   # Commit changes
   git commit -am "Bump version to 0.2.0"
   git push
   
   # Create tags
   ./scripts/create-release.sh 0.2.0 "Release 0.2.0"
   ```

2. **GitHub Actions Method:**
   - Go to Actions → "Coordinated Release Helper"
   - Click "Run workflow"
   - Enter version number (e.g., `0.2.0`)
   - Optionally customize which repos to release
   - Click "Run workflow"

### Staging Deployment

Cloud service automatically deploys to staging on push to `main`:
- Monitor: https://github.com/brewos-io/cloud/actions

### Production Deployment

Production deployments happen via version tags:
- `v0.2.0` → Firmware release
- `app-v0.2.0` → App release
- `cloud-v0.2.0` → Cloud production deployment

## Repository Structure

```
brewos-io/
├── firmware/    # ESP32 & Pico firmware
├── app/         # Progressive Web App
├── cloud/       # Cloud service
├── web/         # Marketing website
└── homeassistant/ # Home Assistant integration
```

## Support

For questions or issues:
- Check [RELEASE_MANAGEMENT.md](RELEASE_MANAGEMENT.md) for versioning questions
- Check [WORKFLOWS.md](WORKFLOWS.md) for workflow questions
- Open an issue in the relevant repository


