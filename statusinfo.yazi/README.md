# statusinfo.yazi

Status bar plugin for [Yazi](https://github.com/sxyazi/yazi) showing Git info and disk space with Dracula colors.

**Left side**: `(git: branch) ✓ 2026-01-01 12:00 commit message`
- Branch name (cyan), VCS status indicators (+staged !modified ?untracked =conflicted)
- Latest commit date and subject

**Right side**: disk free space

## Install

```bash
ya pkg add liangquanzhou/yazi-plugins:statusinfo
```

## Usage

Add to `[plugin]` in `yazi.toml`:

```toml
[[plugin.prepend_preloaders]]
id = "statusinfo"
name = "*"
run = "statusinfo"
```

## License

MIT
