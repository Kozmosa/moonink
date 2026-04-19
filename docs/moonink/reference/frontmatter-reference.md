---
title: Frontmatter Reference
summary: 这一页只列首次用户可以稳定依赖的 frontmatter 字段，并把 layout 放进 advanced/theme-aware 语境。
---

## 稳定字段

| Key | 类型 | 用途 |
| --- | --- | --- |
| `title` | string | 页面标题 |
| `description` | string | 页面描述 |
| `type` | string | 内容类型；常见值是 `page` |
| `date` | string | 日期 |
| `updated` | string | 更新时间 |
| `summary` | string | 摘要 |
| `series` | string | 系列名 |
| `cover` | string | 封面资源路径 |
| `author` | string | 作者名 |
| `column` | string | 栏目名 |
| `tags` | string array | 标签列表 |
| `draft` | boolean | 草稿开关 |

## advanced / theme-aware 字段

| Key | 说明 |
| --- | --- |
| `layout` | 允许值是 `article`、`page`、`home`；只有 active theme 允许 `layout` 作为 page override 时，才适合当成常规写法 |

## 说明

- `.md` 默认就是 article
- `type: page` 会把 Markdown 页面切到 page 路径
- `draft: true` 的内容不会进入最终构建输出

## 不纳入这套首版用户文档主路径的字段

这些字段在当前实现里可能存在相关行为，但不属于这套首次用户文档的稳定 contract：

- `featured`
- `pinned`
- `search`
- `toc`
- `nav_title`
- `nav_hidden`

Guide 版解释见 [[frontmatter]]。
