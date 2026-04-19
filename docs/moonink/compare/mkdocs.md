---
title: MoonInk 与 MkDocs
summary: MkDocs 更偏 docs-first 站点组织，而 MoonInk 更强调 Markdown / Vault 内容根、WikiLink 和逐步接入已有目录。
date: 2026-04-19
tags: [compare, docs]
---

MoonInk 和 MkDocs 都能拿来做文档站，但它们默认假设的内容工作流并不一样。

## MkDocs 常见出发点

- 先定义一个 docs-first 项目结构
- 再围绕导航、站点配置和主题来组织内容

## MoonInk 常见出发点

- 先承认你已经有一个 Markdown folder 或 Vault
- 先让它能 `check`、能 `build`
- 再把首页、section hub、Theme V2 逐步补齐

## MoonInk 更适合哪些情况

- 你不想先做一次大规模内容迁移
- 你希望保留双中括号 WikiLink 和附件写法
- 你希望 page / article 混合，而不是只把内容视作“文档导航节点”

## 什么时候 MkDocs 风格可能更贴近你

- 你的团队已经把信息架构、导航和站点部署流程固定在另一套 docs-first 习惯里
- 你更想从“一个文档项目”出发，而不是从“一个现有内容根”出发

## 怎么判断

如果你现有内容本来就是零散 Markdown、Vault 笔记或混合目录，先看 [[content-model]]、[[routing-and-output]] 和 [从 Markdown Folder 接入](../migration/from-markdown-folder.md) 会更贴近 MoonInk 的思路。
