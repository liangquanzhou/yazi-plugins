# yazi-plugins

Custom [Yazi](https://github.com/sxyazi/yazi) plugins.

## Plugins

### dircount

Unified linemode that shows **file size** for files and **child count** for directories.

- Files: human-readable size (K/M/G/T)
- Directories: async child count (via fetcher)

### statusinfo

Status bar enhancement showing Git info and disk space.

- **Left**: `(git: branch) ✓ 2026-01-01 12:00 commit message` with VCS dirty indicators (+staged !modified ?untracked)
- **Right**: disk free space
- Dracula color scheme, auto-refreshes on `cd`/`tab`

## Install

```bash
ya pkg add liangquanzhou/yazi-plugins:dircount
ya pkg add liangquanzhou/yazi-plugins:statusinfo
```

## License

MIT
