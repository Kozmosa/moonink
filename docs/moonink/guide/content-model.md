---
title: 内容模型
summary: MoonInk 主要处理 article 与 page 两类内容，同时支持根首页推断、HTML page 和 Vault 风格的 README fallback。
tags: [guide, content]
---

MoonInk 的内容模型不复杂，但它会直接影响你的写法、route 和默认展示。理解这一页之后，再看 [[frontmatter]] 和 [[routing-and-output]] 会更顺。

## article 和 page 的区别

- 普通 `.md` 默认按 article 处理。
- `.html` 按 page 处理。
- `.md` 如果写了 `type: page`，也会按 page 处理。

一个实用的判断方式是：

- article 适合连续阅读、长文、教程、示例说明。
- page 适合 landing、section hub、FAQ 这类扫描式页面。

这套文档里，各 section 的 `index.md` 都用了 `type: page`，而大部分深页保留 article 形态，方便你直接看到 built-in article surface。

## 首页规则

根首页优先级是：

1. 根 `index.*`
2. 根 `README.md`

也就是说，如果根目录已经有 `index.md`，MoonInk 就不会再把 `README.md` 当首页。对新站点来说，推荐显式写根 `index.md`；对已有 Vault 来说，`README.md` fallback 很有用。

## Section index 的意义

`getting-started/index.md`、`guide/index.md` 这类文件通常应该是 `type: page`：

- 它们更像目录页而不是长文；
- 它们可以承接 section landing；
- 它们让 article 页面专注解释单一问题。

## HTML page 什么时候有用

如果你已经有一个现成的静态 HTML 页面，也可以直接放进内容树。MoonInk 会把它当 page 接入，而不是强制你改写成 Markdown。

## 和链接、route 的关系

- 内部引用：看 [[linking-and-assets]]
- URL 规则：看 [[routing-and-output]]
- 首页与 Vault 工作流：看 [Obsidian Vault](obsidian-vault.md)
