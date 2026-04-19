---
title: Vault 示例
summary: 一个保留 README 首页、附件目录和 WikiLink 风格的 Obsidian Vault 示例。
series: 示例路线
date: 2026-04-19
tags: [example, obsidian]
---

这个例子适合已经在 Obsidian 里写作的人。重点不是“换结构”，而是“直接接入”。

## 目录

```text
my-vault/
  moonink.json
  README.md
  notes/
    project.md
  Attachments/
    diagram.png
  .obsidian/
  Templates/
```

## `moonink.json`

```json
{
  "site_name": "My Vault",
  "content_dir": ".",
  "output_dir": "dist",
  "exclude": [".obsidian", "dist", ".trash", "Templates"],
  "route_style": "pretty"
}
```

## 首页与正文

`README.md`：

```md
# Vault Home

See \[\[notes/project\]\] and !\[\[Attachments/diagram.png\]\].
```

`notes/project.md`：

```md
# Project Overview

Project note body.
```

## 这个例子展示了什么

- 根 `README.md` 首页 fallback
- 附件资源 embed
- Vault 风格双中括号链接
- `.obsidian` / `Templates` 排除

配套指南见 [Obsidian Vault](../guide/obsidian-vault.md)。
