---
title: 文档站点示例
summary: 一个混合 page 与 article 的结构，适合产品文档、团队手册或内部知识站。
series: 示例路线
date: 2026-04-19
updated: 2026-04-19
tags: [example, docs]
---

如果你的目标不是个人博客，而是结构化文档站，推荐用“section index + article 深页”的组合。

## 目录

```text
docs-site/
  moonink.json
  index.md
  getting-started/
    index.md
    install.md
  guide/
    index.md
    config.md
  public/
    logo.svg
  assets/
    hero.png
```

## 推荐写法

- 根 `index.md` 用 `type: page`
- section 的 `index.md` 也用 `type: page`
- 细页保持 article 默认形态
- 页面之间尽量使用双中括号链接互链，主动形成 backlinks

## 这一类站点最常用到的页面

- 首页：产品定位与入口
- 快速开始：安装与首个站点
- Guide：概念与操作
- Reference：字段和参数表
- FAQ：常见问题

## 为什么这种结构适合 MoonInk

- page 与 article 可以自然混用
- `check` 能先发现 config / link / route 问题
- `public/` 与内容树资源都能直接进入输出

如果你想从这个例子继续走到主题定制，下一步是 [[theme-v2|Theme V2]]。
