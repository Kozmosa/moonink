---
title: FAQ
type: page
summary: 把首次上手最容易卡住的问题集中放在一起，方便快速排查。
---

这一页只回答高频问题。更完整的解释仍然放在 Guide 和 Reference。

## `moonink onboard` 会不会覆盖我已有的 config？

不会。当前目录如果已经有 `moonink.json`，`onboard` 会直接中止。

## 为什么我总被建议先跑 `check`？

因为 `check` 会先把 config、frontmatter、route、wikilink、theme/template 相关问题暴露出来，而且 warning 不会直接失败。它应该是日常写作工作流的一部分。详见 [[check-and-serve]]。

## `check` 通过了，为什么还要 `build`？

`check` 只做 validation，不生成输出。要得到 `dist/`，还是要运行 `build`。

## `serve` 为什么提示 native-only？

这是当前真实边界，不是异常。MoonInk 的真实 HTTP preview 只在 native target 上可用。

## 我能直接拿 Obsidian Vault 来 build 吗？

可以。把 `moonink.json` 放到 Vault 根，确认 `.obsidian` 等目录在 `exclude` 里，然后先跑 `check`。指南见 [Obsidian Vault](guide/obsidian-vault.md)。

## 没有 `index.md` 会怎样？

如果根目录没有 `index.md`，MoonInk 会把根 `README.md` 提升为首页。规则见 [[content-model]]。

## `public/` 和内容树里的资源有什么区别？

- `public/` 会整体复制到输出根
- 内容树里的非 Markdown / HTML 文件会作为 passthrough assets 复制到对应输出位置

说明和示例见 [[linking-and-assets]]。

## 我现在就需要自定义主题吗？

不需要。新站点可以先用 built-in default theme。等内容结构稳定后，再进入 [[theme-v2|Theme V2]]。

## binary install 和 source-run 应该选哪个？

- 直接使用 MoonInk：优先 binary install
- 正在仓库里开发或验证：优先 source-run

安装页见 [[install]]。
