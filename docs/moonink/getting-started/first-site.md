---
title: 第一个站点
summary: 用 onboard、check、build、serve 跑通一套最短路径，理解 MoonInk 的基本目录和输出结果。
---

这一页给你一条 golden path：先初始化 config，再写首页，然后先 `check`、再 `build`，最后按需 `serve`。

## 1. 在内容目录里生成 `moonink.json`

binary 形式：

```bash
moonink onboard
```

source-run 形式：

```bash
moon run src/cmd/main -- onboard
```

`onboard` 不接受 flags 或 positional arguments。它会在当前目录写入 `moonink.json`；如果文件已经存在，会直接中止而不是覆盖。

## 2. 写一个最小首页

创建根 `index.md`：

```md
---
title: 我的第一个 MoonInk 站点
type: page
---

# Hello MoonInk

这是首页内容。
```

根 `index.md` 是推荐首页路径。没有它时，MoonInk 会把根 `README.md` 当作首页，细节见 [[content-model]]。

## 3. 先跑 `check`

binary 形式：

```bash
moonink check
```

source-run 形式：

```bash
moon run src/cmd/main -- check
```

`check` 会走和 `build` 相同的 config / content discovery / build-input 预检路径，但不输出站点文件。warning 不会让命令失败，blocking error 会返回 `1`。这也是为什么它应该放在日常写作流程的前面。完整说明见 [[check-and-serve]]。

## 4. 通过预检后再 `build`

binary 形式：

```bash
moonink build
```

source-run 形式：

```bash
moon run src/cmd/main -- build
```

默认输出目录是 `dist/`。你也可以用 `--output` 临时改到另一个目录，参数表见 [[cli-reference]]。

## 5. 需要预览时再 `serve`

binary 形式：

```bash
moonink serve
```

source-run 形式：

```bash
moon run src/cmd/main --target native -- serve
```

`serve` 会先 build，再启动本地 preview。它的真实 HTTP preview 是 `native-only`；如果你不在 native target 上运行，这不是半成品，而是当前设计边界。

## 接下来建议看什么

- 想改 `moonink.json`：[[config]]
- 想写 metadata：[[frontmatter]]
- 想加入内部链接和图片：[[linking-and-assets]]
- 想理解 route 和 `dist/` 结构：[[routing-and-output]]
