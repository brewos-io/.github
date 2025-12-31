# GitHub Secrets Configuration Guide

This document lists all required GitHub secrets for each repository in the BrewOS organization.

## Overview

Secrets are configured at the repository level in GitHub:
1. Go to repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add the secret name and value
4. Click **Add secret**

## Repository Secrets

### 🔧 Firmware Repository (`brewos-io/firmware`)

#### Required Secrets

| Secret Name | Description | Required For | Notes |
|------------|-------------|-------------|-------|
| `GITHUB_TOKEN` | GitHub token for API access | CI, Releases | ✅ **Auto-provided** - No action needed |

#### Optional Secrets

None - All workflows use the automatically provided `GITHUB_TOKEN`.

#### Usage

- **CI Workflow**: Checks out app repository (requires read access)
- **Release Workflow**: Creates GitHub releases and uploads artifacts

---

### 📱 App Repository (`brewos-io/app`)

#### Required Secrets

| Secret Name | Description | Required For | Notes |
|------------|-------------|-------------|-------|
| `GITHUB_TOKEN` | GitHub token for API access | CI, Releases | ✅ **Auto-provided** - No action needed |

#### Optional Secrets

None - App repository workflows are self-contained.

#### Usage

- **CI Workflow**: Builds and tests app
- **Release Workflow**: Builds release artifacts

---

### ☁️ Cloud Repository (`brewos-io/cloud`)

#### Required Secrets

| Secret Name | Description | Required For | Example/Format |
|------------|-------------|-------------|----------------|
| `GOOGLE_CLIENT_ID` | Google OAuth Client ID | Staging, Production | `123456789-abc.apps.googleusercontent.com` |
| `STAGING_SSH_HOST` | Staging server hostname | Staging Deployment | `staging.brewos.io` (optional, defaults to `staging.brewos.io`) |
| `STAGING_SERVER_SSH_KEY` | SSH private key for staging server | Staging Deployment | SSH private key (see format below) |
| `SERVER_SSH_HOST` | Production server hostname | Production Deployment | `cloud.brewos.io` (optional, defaults to `cloud.brewos.io`) |
| `SERVER_SSH_KEY` | SSH private key for production server | Production Deployment | SSH private key (see format below) |

#### Optional Secrets

| Secret Name | Description | Default |
|------------|-------------|---------|
| `STAGING_SSH_HOST` | Staging server hostname | `staging.brewos.io` |
| `SERVER_SSH_HOST` | Production server hostname | `cloud.brewos.io` |

#### Usage

- **Staging Deployment**: Deploys to staging server on push to `main`
- **Production Deployment**: Deploys to production server on version tags

#### SSH Key Format

SSH keys should be in OpenSSH format. To generate a new key pair:

```bash
# Generate SSH key pair
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/brewos_deploy

# Copy public key to server
ssh-copy-id -i ~/.ssh/brewos_deploy.pub root@staging.brewos.io
ssh-copy-id -i ~/.ssh/brewos_deploy.pub root@cloud.brewos.io

# Copy private key content to GitHub secret
cat ~/.ssh/brewos_deploy
# Copy the entire output (including -----BEGIN and -----END lines)
```

**Important:** 
- Never commit SSH keys to the repository
- Use different keys for staging and production
- Rotate keys periodically

#### Google OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add authorized redirect URIs:
   - `https://staging.brewos.io/auth/google/callback`
   - `https://cloud.brewos.io/auth/google/callback`
6. Copy Client ID to `GOOGLE_CLIENT_ID` secret

---

### 🌐 Web Repository (`brewos-io/web`)

#### Required Secrets

| Secret Name | Description | Required For | Notes |
|------------|-------------|-------------|-------|
| `GITHUB_TOKEN` | GitHub token for API access | Pages Deployment | ✅ **Auto-provided** - No action needed |

#### Optional Secrets

None - Web repository uses GitHub Pages which doesn't require additional secrets.

---

### 🏠 Home Assistant Repository (`brewos-io/homeassistant`)

#### Required Secrets

| Secret Name | Description | Required For | Notes |
|------------|-------------|-------------|-------|
| None | - | - | No workflows currently configured |

---

### 📋 Organization Repository (`.github`)

#### Required Secrets

| Secret Name | Description | Required For | Notes |
|------------|-------------|-------------|-------|
| `GITHUB_TOKEN` | GitHub token for API access | Coordinated Releases | ✅ **Auto-provided** - No action needed |

#### Usage

- **Coordinated Release Workflow**: Creates tags across multiple repositories

---

## Secret Setup Checklist

### For Cloud Repository (Most Important)

- [ ] Generate SSH key pair for staging
- [ ] Add public key to staging server
- [ ] Add `STAGING_SERVER_SSH_KEY` secret (private key)
- [ ] Optionally add `STAGING_SSH_HOST` if different from default
- [ ] Generate SSH key pair for production
- [ ] Add public key to production server
- [ ] Add `SERVER_SSH_KEY` secret (private key)
- [ ] Optionally add `SERVER_SSH_HOST` if different from default
- [ ] Create Google OAuth credentials
- [ ] Add `GOOGLE_CLIENT_ID` secret

### For Other Repositories

- [ ] No action needed - `GITHUB_TOKEN` is automatically provided

---

## Testing Secrets

### Test SSH Connection

```bash
# Test staging connection
ssh -i ~/.ssh/brewos_deploy root@staging.brewos.io

# Test production connection
ssh -i ~/.ssh/brewos_deploy root@cloud.brewos.io
```

### Test Google OAuth

1. Deploy to staging
2. Visit `https://staging.brewos.io`
3. Try to sign in with Google
4. Verify redirect works correctly

---

## Security Best Practices

1. **Use Different Keys**: Use separate SSH keys for staging and production
2. **Rotate Regularly**: Rotate SSH keys and OAuth credentials periodically
3. **Limit Access**: Only grant necessary permissions to OAuth credentials
4. **Monitor Usage**: Review GitHub Actions logs for secret usage
5. **Never Commit**: Never commit secrets to the repository
6. **Use Environments**: Consider using GitHub Environments for production secrets

---

## Troubleshooting

### SSH Connection Fails

- Verify SSH key is correctly formatted (includes headers/footers)
- Check that public key is in `~/.ssh/authorized_keys` on server
- Verify server hostname is correct
- Check server firewall allows SSH (port 22)

### Google OAuth Fails

- Verify `GOOGLE_CLIENT_ID` is correct
- Check authorized redirect URIs in Google Cloud Console
- Ensure OAuth consent screen is configured
- Verify API is enabled

### Workflow Fails with "Secret not found"

- Verify secret name matches exactly (case-sensitive)
- Check that secret is added to the correct repository
- Ensure you have admin access to the repository

---

## Quick Reference

### Minimum Required Secrets

**Cloud Repository Only:**
- `GOOGLE_CLIENT_ID`
- `STAGING_SERVER_SSH_KEY`
- `SERVER_SSH_KEY`

**All Other Repositories:**
- None (use auto-provided `GITHUB_TOKEN`)

### Optional Secrets

- `STAGING_SSH_HOST` (defaults to `staging.brewos.io`)
- `SERVER_SSH_HOST` (defaults to `cloud.brewos.io`)

---

## Support

If you encounter issues with secrets:

1. Check the workflow logs for specific error messages
2. Verify secret names match exactly (case-sensitive)
3. Test SSH connections manually
4. Review this document for setup steps
5. Open an issue in the relevant repository


