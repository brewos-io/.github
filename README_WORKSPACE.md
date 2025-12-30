# BrewOS Organization Workspace

This workspace file allows you to open all BrewOS repositories in Cursor at once.

## Setup

1. **Clone the repositories** (if not already cloned):
   ```bash
   cd /Users/mizrachiran/Projects
   git clone https://github.com/brewos-io/web.git
   git clone https://github.com/brewos-io/homeassistant.git
   # firmware is already at ./all
   ```

2. **Open the workspace in Cursor**:
   ```bash
   cursor /Users/mizrachiran/Projects/brewos-io.code-workspace
   ```
   
   Or from Cursor: File → Open Workspace from File → Select `brewos-io.code-workspace`

## Benefits

- **Multi-repo context**: Cursor's AI can understand code across all repositories
- **Unified search**: Search across all repos at once
- **Easy navigation**: Switch between repos in the sidebar
- **Shared settings**: Common settings apply to all repos

## Repositories

- **firmware** - Main firmware (ESP32, Pico, web UI, cloud)
- **web** - Marketing website (GitHub Pages)
- **homeassistant** - Home Assistant integration

## Notes

- Each repository maintains its own git history
- You can commit/push from each repo independently
- The workspace file is just a convenience - repos can still be opened individually

