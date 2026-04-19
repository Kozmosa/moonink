---
title: Obsidian Vault
summary: MoonInk 可以直接接入 Obsidian Vault：保留 README 首页、附件资源和 WikiLink 写法，不必先把内容改造成另一套结构。
tags: [guide, obsidian]
---

如果你的内容原本就放在 Obsidian Vault 里，MoonInk 的推荐做法不是“迁出再重建”，而是直接在 Vault 根接入。

## 一个最小思路

```text
my-vault/
  moonink.json
  README.md
  notes/
    project.md
  Attachments/
    diagram.png
  .obsidian/
```

其中：

- 根 `README.md` 可以作为首页 fallback
- `Attachments/` 里的资源可以被链接和 embed
- `.obsidian/` 通常应该放进 `exclude`

## 一个最小 config

```json
{
  "site_name": "My Vault",
  "content_dir": ".",
  "output_dir": "dist",
  "exclude": [".obsidian", "dist", ".trash", "Templates"],
  "route_style": "pretty"
}
```

## 主页和资源怎么处理

- 如果根目录已经有 `index.md`，它会优先成为首页
- 如果没有根 `index.md`，根 `README.md` 会成为首页
- 内容树里的附件会被复制到输出目录

这也是为什么 Obsidian 用户通常会同时关心 [[content-model]] 和 [[linking-and-assets]]。

## 推荐工作流

1. 在 Vault 根运行 `onboard`，或者手写 `moonink.json`
2. 先跑 `check`
3. 修正首页、链接和资源路径
4. 再 `build`
5. 需要预览时，用 native 环境 `serve`

## 继续看哪里

- 迁移步骤版：[`from-obsidian-vault`](../migration/from-obsidian-vault.md)
- 示例版：[`examples/obsidian-vault`](../examples/obsidian-vault.md)
