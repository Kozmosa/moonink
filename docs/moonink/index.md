---
title: 月墨 / MoonInk
type: page
summary: 面向首次上手用户的 MoonInk 文档 vault，覆盖安装、首个站点、内容组织、检查预览与 Theme V2。
---

这套文档既是 MoonInk 的 product docs，也是一个可直接 `build` 的 demo vault。它使用 built-in default theme，自身会展示 page / article、双中括号 WikiLink、资源复制和 backlinks 等当前已经 shipped 的能力。

![[assets/vault-diagram.png]]

## MoonInk 适合什么场景

- 你有一个普通 Markdown folder，想快速生成静态站点。
- 你已经在维护 Obsidian Vault，想保留 `README.md`、附件和双中括号 WikiLink 工作流。
- 你想先用 built-in default theme 起步，之后再切到 [[theme-v2|Theme V2]] 自定义主题。

## 两条开始路径

- 从零开始：先看 [[install]]，然后继续 [[first-site]]。
- 从现有内容接入：直接看 [Obsidian Vault 指南](guide/obsidian-vault.md) 或 [迁移入口](migration/index.md)。

## 新用户最先要知道的事

- `check` 是 first-class command。开始 build 之前，先看 [[check-and-serve]]。
- `serve` 只用于 native preview；如果你在非 native target 运行，它报 `native-only` 是预期行为。
- `index.md` 是推荐首页；没有根 `index.md` 时，根 `README.md` 会被提升为首页。细节见 [[content-model]]。
- 当前推荐主题路径是 [[theme-v2|Theme V2]]；`template_file` 只放在兼容说明里。

## 这套文档会带你看到什么

- [[config]]：`moonink.json` 的稳定字段和推荐默认值。
- [[frontmatter]]：内容作者真正需要依赖的 metadata。
- [[linking-and-assets]]：Markdown link、WikiLink、embed、`public/` 和内容树资源。
- [[routing-and-output]]：`pretty` / `direct` route 与输出目录的关系。
- [quick-checklist.txt](/quick-checklist.txt)：一个来自 `public/` 的静态资源示例。
- [moonink-badge.svg](/moonink-badge.svg)：另一个 root public asset 示例。

## 下一步

- 想立刻跑通最短路径：[[first-site]]
- 想先看命令面：[[cli]]
- 想查精确字段：[[cli-reference]]、[[config-reference]]、[[frontmatter-reference]]、[[theme-reference]]
- 想了解取舍：[[quartz]]、[[mkdocs]]
