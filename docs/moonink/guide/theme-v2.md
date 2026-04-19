---
title: Theme V2
summary: Theme V2 是当前推荐的主题 authoring path；如果你暂时不自定义主题，MoonInk 会使用 built-in default theme。
tags: [guide, theme]
---

这页关注的是“什么时候开始自定义主题，以及最小 Theme V2 要长什么样”。如果你只是想先把内容站跑起来，不需要马上写主题。

## 默认情况下会发生什么

如果你的项目没有自定义 `theme`，也没有使用 `template_file`，MoonInk 会回退到 built-in default theme。也就是说：

- 新站点可以先不写主题目录
- 你可以先专注在 [[content-model]]、[[frontmatter]] 和 [[linking-and-assets]]
- 等内容结构稳定后，再进入 Theme V2

## Theme V2 的最小目录

```text
theme/
  theme.json
  layouts/
    index.html
    page.html
    article.html
  partials/
  assets/
```

这就是当前最推荐的主题组织方式。

## 一个最小 manifest

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
  "slots": ["head", "scripts"]
}
```

完整 key 说明见 [[theme-reference]]。

## `theme_config` 怎么用

你可以在 `moonink.json` 里给主题传 token 或 slot 值：

```json
{
  "theme": "theme",
  "theme_config": {
    "color": {
      "bg": "#fff8e1"
    },
    "slots": {
      "head": "<meta name=\"theme-color\" content=\"#fff8e1\">"
    }
  }
}
```

## `layout` 要怎么理解

`layout` 不是 beginner-default frontmatter。它更适合放在 theme-aware 场景里理解：

- frontmatter 允许写 `layout: article | page | home`
- 但只有 active theme 把 `layout` 列进 `page_overrides` allowlist 时，才适合当成常规 override 使用

如果你只是想正常写页面，大多数时候不需要动它。

## `template_file` 放在哪里

`template_file` 仍然是兼容路径，但不是当前推荐主线。新的主题工作优先围绕 Theme V2 目录和 manifest 展开。

## 接下来建议

- 想看 key 表：[[theme-reference]]
- 想回到 config：[[config]]
- 想继续保持默认主题写内容：[[first-site]]
