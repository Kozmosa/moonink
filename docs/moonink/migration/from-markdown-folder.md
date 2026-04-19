---
title: 从 Markdown Folder 接入
summary: 如果你已经有一个普通 Markdown 目录，通常只需要补一个 moonink.json，再决定首页与 route style。
---

这是最直接的一类迁移：你的内容已经是普通 Markdown 文件，只是还没有被 MoonInk 接管。

## 推荐步骤

1. 在目录根加 `moonink.json`
2. 确认根首页使用 `index.md` 或 `README.md`
3. 先跑 `check`
4. 修正文内链接与资源路径
5. 再 `build`

## 一个常见起点

```json
{
  "site_name": "My Notes",
  "content_dir": ".",
  "output_dir": "dist",
  "exclude": ["dist"],
  "route_style": "pretty"
}
```

## 迁移时常见决定

- 想保留目录式 URL：选 `pretty`
- 想保留 `.html` 结尾：选 `direct`
- 想让 section 入口更清楚：补 `type: page` 的 `index.md`

## 迁移后通常会继续做什么

- 补 frontmatter：[[frontmatter]]
- 统一链接写法：[[linking-and-assets]]
- 整理 route：[[routing-and-output]]
