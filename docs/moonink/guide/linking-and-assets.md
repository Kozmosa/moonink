---
title: 链接与资源
summary: MoonInk 支持普通 Markdown 内链、WikiLink、带 label 的 WikiLink、资源型 WikiLink 和图片 embed。
tags: [guide, links]
---

MoonInk 的链接模型兼顾普通 Markdown folder 和 Vault 工作流。你可以从最保守的 Markdown link 开始，也可以直接用双中括号 WikiLink。

## 普通页面链接

普通 Markdown link 适合路径清晰、你想显式写出相对地址的场景：

```md
[配置文件](config.md)
[CLI Reference](../reference/cli-reference.md)
```

## WikiLink

MoonInk 当前支持：

```md
[[config]]
[[frontmatter-reference|Frontmatter Reference]]
```

在这套文档里，你会经常看到 `[[config]]`、`[[cli-reference]]`、`[[theme-v2|Theme V2]]` 这样的链接。它们不只是可读性更强，也会形成 backlinks 网络。

## 资源型 WikiLink 与 embed

内容树里的非 Markdown / HTML 文件会作为 passthrough assets 复制到输出目录，所以你可以直接链接或 embed 它们。

普通资源链接：

```md
[[assets/vault-diagram.png]]
```

图片 embed：

```md
![[assets/vault-diagram.png]]
```

实际效果如下：

![[assets/vault-diagram.png]]

## `public/` 的作用

项目根的 `public/` 会整体复制到输出目录。它适合放：

- `robots.txt`
- `*.svg`
- 需要固定 URL 的静态文件

这页里这个链接就来自 `public/`：

- [quick-checklist.txt](/quick-checklist.txt)

## backlinks 是怎么出现的

backlinks 来自被解析成功的 WikiLink。比如这页链接到了 [[config]]、[[frontmatter]] 和 [[routing-and-output]]，那些页面在构建后就能反向看到来自本页的引用。

## 什么时候用哪一种链接

- 想显式写相对路径：用 Markdown link
- 想保持 Vault 风格：用 WikiLink
- 想引用内容树资源：用资源型 WikiLink
- 想引用 root 静态文件：放进 `public/`

相关主题：

- [Obsidian Vault](obsidian-vault.md)
- [[content-model]]
- [[routing-and-output]]
