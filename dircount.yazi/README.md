# dircount.yazi

Unified linemode plugin for [Yazi](https://github.com/sxyazi/yazi) that shows **file size** for files and **child count** for directories.

- Files: human-readable size (K/M/G/T)
- Directories: async child count via fetcher (purple)

## Install

```bash
ya pkg add liangquanzhou/yazi-plugins:dircount
```

## Usage

Add to `[plugin]` in `yazi.toml`:

```toml
[[plugin.prepend_fetchers]]
id = "dircount"
name = "*/"
run = "dircount"

[[plugin.prepend_preloaders]]
id = "dircount"
name = "*/"
run = "dircount"
```

## License

MIT
