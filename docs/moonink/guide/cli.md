---
title: CLI 命令
summary: MoonInk 当前对外的命令面很小，核心就是 help、onboard、build、check、serve 五个命令。
tags: [guide, cli]
---

MoonInk 的 CLI 是一个刻意收敛的命令面。大多数日常工作只需要 `onboard`、`check`、`build`、`serve`。

## 命令总览

| Command | 作用 | 什么时候用 |
| --- | --- | --- |
| `help` | 查看命令入口 | 第一次确认安装是否成功 |
| `onboard` | 在当前目录写入 `moonink.json` | 把现有目录接入 MoonInk |
| `build` | 生成静态输出 | 需要产出 `dist/` 时 |
| `check` | validation-only 预检 | 写作、迁移、改 config 后先跑 |
| `serve` | build 后启动本地 preview | 本地预览，且仅限 native |

## 最常用的三条命令

binary 形式：

```bash
moonink check
moonink build
moonink serve
```

source-run 形式：

```bash
moon run src/cmd/main -- check
moon run src/cmd/main -- build
moon run src/cmd/main --target native -- serve
```

## `onboard` 的边界

- 不接受 flags 或 positional arguments。
- 只在当前目录写 `moonink.json`。
- 如果文件已经存在，会中止而不是覆盖。

这让 `onboard` 更像“把现有目录接入 MoonInk”，而不是另起一个全新 scaffold。

## 为什么 `check` 要放在 `build` 前面

`check` 和 `build` 走的是同一套输入面，但 `check` 不写输出。它会把 frontmatter、route、wikilink、theme/template 这类问题先暴露出来。细节见 [[check-and-serve]]。

## 参数怎么查

- 精确参数表：[[cli-reference]]
- 输出目录和 route：[[routing-and-output]]
- `moonink.json` 字段：[[config-reference]]
