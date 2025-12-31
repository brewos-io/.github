# Development Documentation

This section contains guides for developing BrewOS.

## Contents

- [GitHub Actions Workflows](WORKFLOWS.md) - Complete CI/CD pipeline documentation

## Development Workflow

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes and test locally**

3. **Push and create PR:**
   ```bash
   git push origin feature/my-feature
   ```

4. **CI will automatically run:**
   - Linting
   - Type checking
   - Build verification
   - Tests (where applicable)

## Repository-Specific Development

- **Firmware**: See [firmware docs](https://github.com/brewos-io/firmware/tree/main/docs)
- **App**: See [app README](https://github.com/brewos-io/app#development)
- **Cloud**: See [cloud README](https://github.com/brewos-io/cloud#development)

