---
title: 最小站点示例
summary: 一个只有 moonink.json 与根 index.md 的最小 MoonInk 站点。
series: 示例路线
date: 2026-04-19
tags: [example, minimal]
---

这个例子适合验证“MoonInk 到底最少需要什么”。答案是：一个 `moonink.json`，再加一个首页文件。

## 目录

```text
my-site/
  moonink.json
  index.md
```

## `moonink.json`

```json
{
  "site_name": "My Site",
  "content_dir": ".",
  "output_dir": "dist",
  "exclude": ["dist"],
  "route_style": "pretty"
}
```

## `index.md`

```md
---
title: Home
type: page
---

# Hello MoonInk
```

## 建议执行顺序

```bash
moonink check
moonink build
```

source-run 形式：

```bash
moon run src/cmd/main -- check
moon run src/cmd/main -- build
```

## 什么时候从最小站点升级

- 需要 section hub：开始加 `guide/index.md` 这类 `type: page`
- 需要文章页：开始加普通 `.md`
- 需要更完整结构：继续看 [[docs-site]]
