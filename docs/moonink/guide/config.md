---
title: 配置文件
summary: MoonInk 使用一个项目根级别的 moonink.json，内容不多，但会决定内容根、输出目录、route 风格和主题路径。
tags: [guide, config]
---

`moonink.json` 是 MoonInk 站点的入口配置。对于大多数新站点来说，你先理解这几个字段就够了：`site_name`、`content_dir`、`output_dir`、`exclude`、`route_style`。

## 一个最小可用例子

```json
{
  "site_name": "My Site",
  "content_dir": ".",
  "output_dir": "dist",
  "exclude": ["dist"],
  "route_style": "pretty"
}
```

这也是很多内容型站点的推荐起点。

## 一个更接近日常使用的例子

```json
{
  "site_name": "My Site",
  "site_url": "https://example.com",
  "content_dir": ".",
  "output_dir": "dist",
  "exclude": [".obsidian", "dist", ".git", "node_modules", ".trash", "templates", "Templates"],
  "route_style": "pretty"
}
```

这类配置适合直接接入已有目录或 Vault。

## Obsidian-friendly 例子

```json
{
  "site_name": "My Vault",
  "content_dir": ".",
  "output_dir": "dist",
  "exclude": [".obsidian", "dist", ".trash", "Templates"],
  "route_style": "pretty"
}
```

如果你的 Vault 根目录里还有附件、笔记子目录和 `README.md`，这通常已经够用。配套工作流见 [Obsidian Vault](obsidian-vault.md)。

## Theme V2 例子

```json
{
  "site_name": "My Site",
  "content_dir": ".",
  "output_dir": "dist",
  "route_style": "pretty",
  "theme": "theme",
  "theme_config": {
    "color": {
      "bg": "#fff8e1"
    },
    "slots": {
      "head": "<meta name=\"color-scheme\" content=\"light\">"
    }
  }
}
```

如果你没有配置 `theme` 或 `template_file`，MoonInk 会回退到 built-in default theme。想自己写主题时，再进入 [[theme-v2|Theme V2]] 即可。

## 字段怎么分层理解

- 日常必备：`site_name`、`content_dir`、`output_dir`、`exclude`、`route_style`
- 常见补充：`site_url`
- 主题相关：`theme`、`theme_config`
- 兼容路径：`template_file`

完整字段表见 [[config-reference]]。
