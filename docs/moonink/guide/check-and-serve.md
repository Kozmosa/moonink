---
title: 检查与预览
summary: check 用来提前暴露问题，serve 用来本地预览；它们的职责不同，而且 serve 明确是 native-only。
tags: [guide, workflow]
---

这两个命令经常一起出现，但它们不是同一种工具。简单记法是：先 `check`，再 `build`，最后按需 `serve`。

## `check` 做什么

`check` 会复用构建前半段的真实路径：

- 读取 `moonink.json`
- 发现内容与资源
- 解析 frontmatter
- 做 route、wikilink、theme/template 相关检查

它不会输出站点文件，所以特别适合放在日常写作和迁移流程前面。

## `check` 的返回语义

- 只有 warning：返回 `0`
- 有 blocking error：返回 `1`

也就是说，warning 会被报告出来，但不会阻断你继续修正内容；真正阻断构建的是 error。

## `check` 常见用法

binary 形式：

```bash
moonink check
moonink check --config docs/moonink/moonink.json
moonink check --config docs/moonink/moonink.json --output preview-dist
```

source-run 形式：

```bash
moon run src/cmd/main -- check
moon run src/cmd/main -- check --config docs/moonink/moonink.json
```

## `serve` 做什么

`serve` 的职责是：

1. 先完成一次 build
2. 再把结果交给本地 preview runtime

所以它不是一个“跳过构建”的命令，而是一个“先构建、再预览”的命令。

## `serve` 的关键边界：native-only

MoonInk 的真实 HTTP preview 只在 native target 上可用。你应该把这条约束写进自己的团队工作流里：

- 日常内容预检：先 `check`
- 产出文件：再 `build`
- 本地预览：仅在 native 环境下 `serve`

binary 形式：

```bash
moonink serve --config docs/moonink/moonink.json --host 127.0.0.1 --port 3000
```

source-run 形式：

```bash
moon run src/cmd/main --target native -- serve --config docs/moonink/moonink.json --host 127.0.0.1 --port 3000
```

## 什么情况先看哪一条命令

- 改了 frontmatter、route、link：先 `check`
- 想确认输出目录内容：`build`
- 想在浏览器里预览：`serve`

命令参数见 [[cli-reference]]，最短起步流程见 [[first-site]]。
