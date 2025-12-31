# BrewOS Organization Workspace

This workspace file allows you to open all BrewOS repositories in Cursor/VS Code at once.

## Quick Start

1. **Clone all repositories** (if not already cloned):

   ```bash
   mkdir brewos-io && cd brewos-io
   git clone https://github.com/brewos-io/firmware.git
   git clone https://github.com/brewos-io/app.git
   git clone https://github.com/brewos-io/cloud.git
   git clone https://github.com/brewos-io/web.git
   git clone https://github.com/brewos-io/homeassistant.git
   ```

2. **Open the workspace:**

   ```bash
   cursor brewos-io.code-workspace
   ```

   Or from Cursor: **File → Open Workspace from File** → Select `brewos-io.code-workspace`

## Benefits

- **Multi-repo context**: Cursor's AI can understand code across all repositories
- **Unified search**: Search across all repos at once
- **Easy navigation**: Switch between repos in the sidebar
- **Shared settings**: Common settings apply to all repos
- **Unified Source Control**: See changes from all repositories in one view

## Repositories

- **firmware** - ESP32 and Pico firmware
- **app** - Progressive Web App (shared between ESP32 and cloud)
- **cloud** - Cloud service for remote access
- **web** - Marketing website (GitHub Pages)
- **homeassistant** - Home Assistant integration

## Troubleshooting

If you don't see changes from all repositories in the Source Control view:

1. **Reload the workspace**: `Cmd+Shift+P` → "Reload Window"
2. **Check repository selector**: Look for dropdown in Source Control view
3. **Verify git repositories**: Each folder should be a git repository (check for `.git` directory)

## Notes

- Each repository maintains its own git history
- You can commit/push from each repo independently
- The workspace file is just a convenience - repos can still be opened individually
- See [Documentation](docs/README.md) for more information
