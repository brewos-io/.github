# Deployment Documentation

This section contains guides for deploying and releasing BrewOS.

## Contents

- [Release Management](RELEASE_MANAGEMENT.md) - Versioning strategy and release process
- [Secrets Configuration](SECRETS.md) - Required GitHub secrets for deployments

## Quick Reference

### Staging Deployment
- **Cloud**: Auto-deploys on push to `main`
- Monitor: [Cloud Actions](https://github.com/brewos-io/cloud/actions)

### Production Deployment
- **Firmware**: Tag `v0.2.0` → Creates release
- **App**: Tag `app-v0.2.0` → Builds artifacts
- **Cloud**: Tag `cloud-v0.2.0` → Deploys to production

### Coordinated Release
Use the [coordinated release workflow](../.github/workflows/coordinated-release.yml) or scripts:
```bash
./scripts/bump-version.sh 0.2.0
./scripts/create-release.sh 0.2.0 "Release message"
```

## Repository-Specific Deployment

- **Firmware**: See [firmware release workflow](https://github.com/brewos-io/firmware/blob/main/.github/workflows/release.yml)
- **App**: See [app release workflow](https://github.com/brewos-io/app/blob/main/.github/workflows/release.yml)
- **Cloud**: See [cloud deployment workflows](https://github.com/brewos-io/cloud/tree/main/.github/workflows)

