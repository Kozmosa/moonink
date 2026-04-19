---
title: Theme Reference
summary: Theme V2 的核心接口包括 manifest key、目录约定、token 命名规则，以及 page_overrides / slots 这两个主题扩展点。
---

## `theme.json` key

| Key | 类型 | 用途 |
| --- | --- | --- |
| `name` | string | 主题名 |
| `layouts` | object | layout key 到模板文件的映射 |
| `tokens` | array | 主题 token 声明 |
| `page_overrides` | string array | 允许的 page override key allowlist |
| `slots` | string array | 主题声明可接受的 slot 名 |

## 目录约定

| 路径 | 作用 |
| --- | --- |
| `theme/theme.json` | manifest |
| `theme/layouts/` | 布局模板 |
| `theme/partials/` | partial 模板 |
| `theme/assets/` | 主题静态资源 |

## 最小 manifest

```json
{
  "name": "my-theme",
  "layouts": {
    "index": "layouts/index.html",
    "page": "layouts/page.html",
    "article": "layouts/article.html"
  },
  "tokens": [
    { "name": "color.bg", "default": "#fff8e1" }
  ],
  "page_overrides": ["layout"],
  "slots": ["head", "scripts"]
}
```

## token 命名规则

token `name` 使用点分段的 lowercase ASCII letters / digits 风格，例如：

- `color.bg`
- `color.accent`
- `spacing.gap`

## `page_overrides` 怎么理解

`page_overrides` 不是普通内容作者每天都会碰到的字段，它是主题作者用来声明“这套主题允许哪些页面级 override”的地方。

一个常见例子是：

```json
{
  "page_overrides": ["layout"]
}
```

这意味着该主题接受页面 frontmatter 里的 `layout` override。

Guide 版说明见 [[theme-v2|Theme V2]]。
