---
title: 页面元数据
summary: MoonInk 的 frontmatter 以内容作者真正会用到的字段为主，先掌握 title、summary、tags、draft 和 type 就已经足够高频。
tags: [guide, frontmatter]
---

frontmatter 用来描述页面本身，而不是替代整站配置。对于第一次上手的用户，最常用的是 `title`、`summary`、`tags`、`draft` 和 `type`。

## page frontmatter

```yaml
---
title: 快速开始
type: page
summary: 这一页负责导航，不负责长篇正文。
---
```

当一页更像 landing、hub、FAQ，而不是长文时，使用 `type: page`。

## article frontmatter

```yaml
---
title: 第一个站点
summary: 用 onboard、check、build、serve 跑通第一轮流程。
tags: [guide, quickstart]
---
```

没有 `type: page` 的 `.md` 会按 article 处理，这也是 MoonInk 的默认路径。

## 带更多 metadata 的例子

```yaml
---
title: 文档站点示例
description: 一个混合 page 与 article 的小型文档站。
date: 2026-04-19
updated: 2026-04-19
summary: 用真实目录结构展示 MoonInk 的推荐写法。
series: 示例路线
cover: assets/vault-diagram.png
author: MoonInk Team
column: Docs
tags: [example, docs]
draft: false
---
```

这些字段都属于当前可以稳定写进用户文档的范围，精确表格见 [[frontmatter-reference]]。

## `draft` 的语义

`draft: true` 的内容不进入最终构建输出，也不会参与公开可见的生成面。它很适合拿来写暂存草稿，但不要把它当成“半公开发布”开关。

## `layout` 为什么不放在新手主路径

MoonInk 当前确实支持 `layout`，但它属于 theme-aware override：

- 允许值是 `article`、`page`、`home`
- 只有 active theme 明确允许 `layout` 作为 page override 时，才适合把它当成常规写法

所以对 built-in default theme + 首次上手用户来说，你通常不需要写 `layout`。更适合先理解 [[theme-v2|Theme V2]] 的主题边界。

## 什么时候继续往下看

- 想查字段表：[[frontmatter-reference]]
- 想看资源和链接如何写：[[linking-and-assets]]
- 想知道 `type: page` 如何影响 route 和首页：[[content-model]]
