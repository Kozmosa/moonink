---
title: MoonInk 与 Quartz
summary: 两者都适合处理 Markdown 与知识笔记，但 MoonInk 更强调当前可验证的本地构建边界、CLI workflow 与 shipped-only 文档化。
date: 2026-04-19
tags: [compare, notes]
---

如果你熟悉 Quartz，理解 MoonInk 最好的方式不是问“谁更强”，而是问“谁的默认工作流更贴近我现在的内容目录”。

## MoonInk 更像什么

- 一个围绕 `onboard`、`check`、`build`、`serve` 收敛起来的本地 CLI workflow
- 一个对普通 Markdown folder 和 Obsidian Vault 都友好的静态构建器
- 一个把 Theme V2 作为推荐主题路径的内容站工具

## 什么时候 MoonInk 更顺手

- 你想先用最少 config 跑起来
- 你希望 `check` 在写作流程里有明确位置
- 你希望文档能严格贴着当前 shipped behavior，而不是先写未来 contract

## 什么时候你可能更在意别的工具

- 你更看重某套既有的知识花园生态和社区约定
- 你已经围绕另一套主题或插件模型深度定制

## 一个实际判断法

先把你现有内容目录放进 MoonInk，跑一次 [[first-site]] 或 [Obsidian Vault 指南](../guide/obsidian-vault.md)。如果 `check` 和 `build` 的反馈已经符合你的工作方式，MoonInk 就值得继续留下来。
